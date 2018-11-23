
#[derive(Debug)]
pub enum Crypto {
    TimeError,
    Signature,
    InvalidToken,
    InvalidUserName,
}

impl std::convert::From<Crypto> for rocket::http::Status {
    fn from(error: Crypto) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::InternalServerError
    }
}

// ==========================================================================

#[derive(Debug)]
pub enum RequestError {
    NotAValidToken,
    NoToken,
}

impl std::convert::From<RequestError> for rocket::http::Status {
    fn from(error: RequestError) -> rocket::http::Status {
        println!("error: {:?}", error);
        rocket::http::Status::Unauthorized
    }
}

