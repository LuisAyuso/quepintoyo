#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;

#[macro_use(bson, doc)]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate serde_json;

extern crate hex;
extern crate rand;

extern crate crypto;
extern crate jwt;
extern crate rustc_serialize;

#[macro_use(serialize_tools)]
extern crate qpy_core;

mod appstate;
mod db;
mod error;
mod web;
mod login;

fn main() {
    let db_host = "192.168.0.2";
    let db_port = 27017;

    //    let db_host = "localhost";
    //    let db_port = 27017;

    db::hello(db_host, db_port);

    let connection = db::Connection::new(db_host, db_port).expect("could not connect to mongo");
    let app = appstate::AppState::new(connection);
    web::kickstart(app);
}
