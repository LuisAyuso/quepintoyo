use mongodb::bson;
use serde_json;

use crate::error;

pub trait Convert {
    type Elem;

    fn to_json(&self) -> Result<String, error::Conversion>;
    fn from_json(data: &str) -> Result<Self::Elem, error::Conversion>;

    fn to_bson(&self) -> Result<bson::Document, error::Conversion>;
    fn from_bson(doc: bson::Document) -> Result<Self::Elem, error::Conversion>;
}

#[macro_export]
macro_rules! serialize_tools {
    ( $typename:ty ) => {
        impl $crate::conversion::Convert for $typename {
            type Elem = Self;

            fn to_json(&self) -> Result<String, error::Conversion> {
                serde_json::to_string(self).map_err(|_| error::Conversion::JsonFailed)
            }
            fn from_json(data: &str) -> Result<Self, error::Conversion> {
                let v: Self =
                    serde_json::from_str(data).map_err(|_| error::Conversion::JsonFailed)?;
                Ok(v)
            }

            fn to_bson(&self) -> Result<bson::Document, error::Conversion> {
                bson::to_bson(&self)
                    .and_then(|entry| match entry {
                        bson::Bson::Document(doc) => Ok(doc),
                        _ => Err(bson::EncoderError::Unknown(
                            "error during encoding".to_string(),
                        )),
                    })
                    .map_err(|_| error::Conversion::BsonFailed)
            }

            fn from_bson(doc: bson::Document) -> Result<Self, error::Conversion> {
                let data: Self = bson::from_bson(bson::Bson::Document(doc))
                    .map_err(|_| error::Conversion::BsonFailed)?;
                Ok(data)
            }
        }
    };
}

#[cfg(test)]
mod tests {

    use super::*;
    use crate::error;

    #[derive(Serialize, Deserialize, PartialEq, Eq, Debug, Clone, Default)]
    pub struct TestData {
        pub string: String,
        pub int: i32,
    }

    serialize_tools!(TestData);

    #[test]
    fn to_doc() {
        let data = TestData {
            ..Default::default()
        };
        let bson_doc = data.to_bson().expect("this must go");
        let data2 = TestData::from_bson(bson_doc).expect("ok");
        assert_eq!(data, data2);
    }
}
