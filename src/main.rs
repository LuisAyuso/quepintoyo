#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;

#[macro_use(bson, doc)]
extern crate mongodb;

#[macro_use]
extern crate serde_derive;

extern crate hex;
extern crate rand;

extern crate crypto;
extern crate jwt;

#[macro_use]
mod conversion;

mod appstate;
mod db;
mod error;
mod web;

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
