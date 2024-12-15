use anyhow::Result;
use axum::{
    body::Body,
    extract::{Path, State},
    http::{
        header::{self, InvalidHeaderValue, ToStrError},
        HeaderMap, HeaderValue, StatusCode,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use clap::Parser;
use opendal::{services::S3, ErrorKind, Operator};
use std::sync::Arc;
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("opendal error")]
    Opendal(#[from] opendal::Error),
    #[error("header error")]
    Header(#[from] InvalidHeaderValue),
    #[error("to str error")]
    ToStr(#[from] ToStrError),
}

impl IntoResponse for Error {
    fn into_response(self) -> axum::response::Response {
        match self {
            Self::Opendal(err) => match err.kind() {
                ErrorKind::NotFound => {
                    tracing::info!(error = err.to_string());
                    StatusCode::NOT_FOUND
                }
                ErrorKind::ConditionNotMatch => StatusCode::NOT_MODIFIED,
                _ => {
                    tracing::error!(error = err.to_string());
                    StatusCode::INTERNAL_SERVER_ERROR
                }
            }
            .into_response(),
            _ => {
                tracing::error!(error = self.to_string());
                StatusCode::INTERNAL_SERVER_ERROR
            }
            .into_response(),
        }
    }
}

async fn serve(
    State(operator): State<Arc<Operator>>,
    headers: HeaderMap,
    Path(path): Path<String>,
) -> Result<impl IntoResponse, Error> {
    let metadata = if let Some(etag) = headers.get(header::IF_NONE_MATCH) {
        operator
            .stat_with(&path)
            .if_none_match(etag.to_str()?)
            .await?
    } else {
        operator.stat(&path).await?
    };

    let reader = operator.reader(&path).await?;
    let mut headers = HeaderMap::new();

    for (k, v) in [
        (header::CONTENT_TYPE, metadata.content_type()),
        (
            header::CONTENT_LENGTH,
            Some(&metadata.content_length().to_string()),
        ),
        (header::ETAG, metadata.etag()),
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
    Ok((
        headers,
        Body::from_stream(reader.into_bytes_stream(..).await?),
    ))
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

    let operator = Operator::new(
        S3::default()
            .region(&args.s3_region)
            .endpoint(&args.s3_endpoint)
            .bucket(&args.s3_bucket),
    )?
    .finish();

    let app = Router::new()
        .layer(TraceLayer::new_for_http())
        .route("/*path", get(serve))
        .with_state(Arc::new(operator));

    let listener = TcpListener::bind(&args.listen).await?;

    Ok(axum::serve(listener, app).await?)
}
