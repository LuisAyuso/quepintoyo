use mongodb::bson as bson;
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

            fn to_json(&self) -> Result<String, $crate::error::Conversion> {
                serde_json::to_string(self).map_err(|_| $crate::error::Conversion::JsonFailed)
            }
            fn from_json(data: &str) -> Result<Self, $crate::error::Conversion> {
                let v: Self =
                    serde_json::from_str(data).map_err(|_| $crate::error::Conversion::JsonFailed)?;
                Ok(v)
            }

            fn to_bson(&self) -> Result<bson::Document, $crate::error::Conversion> {
                bson::to_bson(&self)
                    .and_then(|entry| match entry {
                        bson::Bson::Document(doc) => Ok(doc),
                        _ => Err(bson::EncoderError::Unknown(
                            "error during encoding".to_string(),
                        )),
                    })
                    .map_err(|_| $crate::error::Conversion::BsonFailed)
            }

            fn from_bson(doc: bson::Document) -> Result<Self, $crate::error::Conversion> {
                let data: Self = bson::from_bson(bson::Bson::Document(doc))
                    .map_err(|_| $crate::error::Conversion::BsonFailed)?;
                Ok(data)
            }
        }
    };
}

// ===================================================================================

pub struct VersionConvert<Type,Proxy>
where Type: From<<Proxy as Convert>::Elem>,
      Proxy:  Convert
{
    t: std::marker::PhantomData<Type>,
    p: std::marker::PhantomData<Proxy>,
}

impl<Type,Proxy> VersionConvert<Type,Proxy>
where Type: From<<Proxy as Convert>::Elem>,
      Proxy:  Convert
{ 
    pub fn version_from_json(data: &str) -> Result<Type, error::Conversion>{
        Proxy::from_json(data).map(|obj| obj.into())
    }
    pub fn version_from_bson(doc: bson::Document) -> Result<Type, error::Conversion>{
        Proxy::from_bson(doc).map(|obj| obj.into())
    }
}

// a macro that tries to convert from any of the given versions: 
// target type + list of version types to try from
#[macro_export]
macro_rules! try_deserialize_bson {
    ($expr:expr => $target:ty : $($proxy:ty),+) => {
        {
            $(
                type T = $proxy;
                if let Ok(v) = T::from_bson($expr.clone()){
                    let res : $target = v.into();
                    Ok(res)
                }
            )+
            else{
                Err($crate::error::Conversion::VersionUnknown)
            }
        }
    }
}

// ====================================================================================
// ====================================================================================

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

