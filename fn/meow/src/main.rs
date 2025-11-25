use argh::FromArgs;
use axum::{
    body::Body,
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, get_service, post},
    Router,
};
use futures::{StreamExt, TryStreamExt};
use std::net::SocketAddr;
use tokio::io::AsyncBufReadExt;
use tokio_util::compat::FuturesAsyncReadCompatExt;
use tower_http::services::ServeDir;
use url::Url;

mod bip39;

async fn index(State(config): State<AppConfig>) -> impl IntoResponse {
    format!(
        "meow - paste bin\nusage: curl --data-binary @<file> {}\n",
        config.base_url
    )
}

async fn paste(
    State(config): State<AppConfig>,
    body: Body,
) -> Result<String, (StatusCode, &'static str)> {
    let key = crate::bip39::mnemonic(config.key_size);
    let mut path = std::path::PathBuf::from(&config.data_dir);
    path.push(&key);
    let mut body = body
        .into_data_stream()
        .map(|item| item.map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, err)))
        .into_async_read()
        .compat();
    let peek = body.fill_buf().await.map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "failed to peek into body",
        )
    })?;
    if infer::is_image(peek) || infer::is_video(peek) {
        return Err((
            StatusCode::FORBIDDEN,
            "image or video files are not allowed",
        ));
    }
    let mut file = tokio::fs::OpenOptions::new()
        .create_new(true)
        .write(true)
        .open(path)
        .await
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "failed to create file"))?;
    tokio::io::copy_buf(&mut body, &mut file)
        .await
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "failed to write to file"))?;
    Ok(format!(
        "{}\n",
        config.base_url.join(&key).unwrap().to_string()
    ))
}

#[derive(FromArgs, Clone)]
/// paste bin
struct AppConfig {
    /// address to listen on (default: 127.0.0.1:3000)
    #[argh(option, short = 'l', default = "\"127.0.0.1:3000\".parse().unwrap()")]
    listen: SocketAddr,
    /// base url
    #[argh(option, short = 'b')]
    base_url: Url,
    /// key size (default: 3)
    #[argh(option, short = 's', default = "3")]
    key_size: usize,
    /// data dir
    #[argh(option, short = 'd')]
    data_dir: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: AppConfig = argh::from_env();

    let app = Router::new()
        .layer(tower_http::limit::RequestBodyLimitLayer::new(
            20 * 1024 * 1024, // limit request body to 20M
        ))
        .route("/", get(index))
        .route("/", post(paste))
        .fallback_service(get_service(ServeDir::new(&args.data_dir)))
        .with_state(args.clone());

    let listener = tokio::net::TcpListener::bind(&args.listen).await?;

    Ok(axum::serve(listener, app.into_make_service()).await?)
}
