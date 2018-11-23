
#[macro_use]
extern crate rocket;

#[macro_use(bson, doc)]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;


pub mod conversion;
pub mod error;
pub mod db;