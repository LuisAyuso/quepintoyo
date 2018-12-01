#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;
extern crate rocket_contrib;

#[macro_use]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;
extern crate serde_json;

extern crate hex;
extern crate rand;

extern crate crypto;
extern crate jwt;
extern crate rustc_serialize;

#[macro_use(serialize_tools, try_deserialize_bson)]
extern crate qpy_core;

#[macro_use]
extern crate elm_generator;

mod appstate;
mod error;
mod web;
mod login;

fn main() {
    let db_host = "192.168.0.2";
    let db_port = 27017;

    //    let db_host = "localhost";
    //    let db_port = 27017;

    qpy_core::db::hello(db_host, db_port);

    let connection = qpy_core::db::Connection::new(db_host, db_port).expect("could not connect to mongo");
    let app = appstate::AppState::new(connection);
    web::kickstart(app);
}
