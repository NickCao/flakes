use anyhow::Result;
use axum::{
    extract::{Path, State},
    http::{
        header::{self, InvalidHeaderValue, ToStrError},
        HeaderMap, HeaderValue, StatusCode,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use axum_extra::body::AsyncReadBody;
use clap::Parser;
use std::sync::Arc;
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("header error: {0}")]
    Header(#[from] InvalidHeaderValue),
    #[error("to str error: {0}")]
    ToStr(#[from] ToStrError),
    #[error("get object error: {0}")]
    GetObject(
        #[from] aws_sdk_s3::error::SdkError<aws_sdk_s3::operation::get_object::GetObjectError>,
    ),
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        match self {
            Self::GetObject(err) => {
                tracing::error!(error = aws_sdk_s3::error::DisplayErrorContext(&err).to_string());
                if let Some(raw) = err.raw_response() {
                    StatusCode::from_u16(raw.status().as_u16())
                        .unwrap_or(StatusCode::INTERNAL_SERVER_ERROR)
                } else {
                    StatusCode::INTERNAL_SERVER_ERROR
                }
            }
            _ => {
                tracing::error!(error = self.to_string());
                StatusCode::INTERNAL_SERVER_ERROR
            }
        }
        .into_response()
    }
}

async fn serve(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Path(path): Path<String>,
) -> Result<impl IntoResponse, Error> {
    let object = if let Some(etag) = headers.get(header::IF_NONE_MATCH) {
        state
            .client
            .get_object()
            .bucket(&state.bucket)
            .key(&path)
            .if_none_match(etag.to_str()?)
    } else {
        state.client.get_object().bucket(&state.bucket).key(&path)
    }
    .send()
    .await?;

    let mut headers = HeaderMap::new();

    for (k, v) in [
        (header::CONTENT_TYPE, object.content_type()),
        (
            header::CONTENT_LENGTH,
            object.content_length().map(|i| i.to_string()).as_deref(),
        ),
        (header::ETAG, object.e_tag()),
        (
            header::CACHE_CONTROL,
            Some("public, max-age=2419200, immutable"),
        ),
        (header::X_CONTENT_TYPE_OPTIONS, Some("nosniff")),
        (
            header::CONTENT_SECURITY_POLICY,
            Some("default-src 'none'; form-action 'none'"),
        ),
    ] {
        if let Some(v) = v {
            headers.insert(k, HeaderValue::from_str(v)?);
        }
    }
    Ok((headers, AsyncReadBody::new(object.body.into_async_read())))
}

struct AppState {
    client: aws_sdk_s3::Client,
    bucket: String,
}

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg(long, env, default_value = "us-east-1")]
    s3_region: String,
    #[arg(long, env)]
    s3_endpoint: String,
    #[arg(long, env)]
    s3_bucket: String,
    #[arg(long)]
    listen: String,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::from_default_env())
        .with(tracing_subscriber::fmt::layer())
        .init();

    let client = aws_sdk_s3::Client::from_conf(
        aws_sdk_s3::config::Builder::from(
            &aws_config::defaults(aws_config::BehaviorVersion::latest())
                .endpoint_url(&args.s3_endpoint)
                .region(aws_config::Region::new(args.s3_region))
                .credentials_provider(
                    aws_config::environment::EnvironmentVariableCredentialsProvider::new(),
                )
                .load()
                .await,
        )
        .build(),
    );

    let app = Router::new()
        .layer(TraceLayer::new_for_http())
        .route("/*path", get(serve))
        .with_state(Arc::new(AppState {
            client,
            bucket: args.s3_bucket,
        }));

    let listener = TcpListener::bind(&args.listen).await?;

    Ok(axum::serve(listener, app).await?)
}
