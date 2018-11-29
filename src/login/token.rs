use serde_json;

//use mongodb::bson;

use crypto::sha2::Sha256;
use std::default::Default;

use qpy_core::conversion::*;
//use qpy_core::db;

use crate::error;


// =========================================================

const KEY: &'static [u8] = b"quepintoyo secret";

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
pub struct Token(String);
type TokType = jwt::Token<jwt::Header, jwt::Claims>;

impl Token {
    pub fn new(name: &str) -> Result<Token, error::Crypto> {
        let header: jwt::Header = Default::default();
        let mut claims = jwt::Claims::new(jwt::Registered {
            iss: Some("quepintoyo.com".into()),
            sub: Some(name.into()),
            ..Default::default()
        });

        use rustc_serialize::json::Json;
        let name_json = Json::String(name.to_string());
        claims
            .private
            .entry("user".to_string())
            .or_insert(name_json);

        let token = jwt::Token::new(header, claims);
        let token = token
            .signed(KEY, Sha256::new())
            .map_err(|_| error::Crypto::Signature)?;
        Ok(Token(token.into()))
    }

    pub fn get_user_name(&self) -> Result<String, error::Crypto> {
        match Self::inner_token_from_str(self.0.as_str()) {
            Ok(tok) => match tok.claims.private.get("user") {
                Some(name) => {
                    let decoded = name
                        .as_string()
                        .ok_or_else(|| error::Crypto::InvalidUserName)?;
                    Ok(decoded.to_string())
                }
                _ => Err(error::Crypto::InvalidToken),
            },
            _ => Err(error::Crypto::InvalidToken),
        }
    }

    pub fn from_str(token_str: &str) -> Result<Token, error::Crypto> {
        match Self::inner_token_from_str(token_str) {
            Err(_) => Err(error::Crypto::InvalidToken),
            Ok(t) => {
                if t.verify(KEY, Sha256::new()) {
                    Ok(Token(token_str.to_string()))
                } else {
                    Err(error::Crypto::InvalidToken)
                }
            }
        }
    }

    fn inner_token_from_str(token_str: &str) -> Result<TokType, error::Crypto> {
        match TokType::parse(token_str) {
            Err(_) => Err(error::Crypto::InvalidToken),
            Ok(t) => Ok(t),
        }
    }
}

impl std::string::ToString for Token {
    fn to_string(&self) -> String {
        self.0.clone()
    }
}

impl<'a, 'r> rocket::request::FromRequest<'a, 'r> for Token {
    type Error = crate::login::error::RequestError;

    fn from_request(
        request: &'a rocket::request::Request<'r>,
    ) -> rocket::request::Outcome<Self, Self::Error> {
        use rocket::http::Status;
        use rocket::Outcome::{Failure, Success};
        use crate::login::error::RequestError;

        let keys: Vec<_> = request.headers().get("Authorization").collect();
        match keys.len() {
            0 => Failure((Status::Unauthorized, RequestError::NoToken)),
            1 => {

                println!("{}", keys[0]);
                let key = keys[0];
                if !key.starts_with("Bearer ") {
                    return Failure((Status::Unauthorized, RequestError::NoToken));
                }
                let (_, token) = key.split_at(7);

                match Token::from_str(token) {
                    Ok(t) => Success(t),
                    Err(_) => Failure((Status::Unauthorized, RequestError::NotAValidToken)),
                }
            }
            _ => Failure((Status::Unauthorized, RequestError::NoToken)),
        }
    }
}


// =========================================================

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn token_test() {
    }
}