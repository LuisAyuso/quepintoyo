#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] 
extern crate rocket;

#[macro_use(bson, doc)]
extern crate bson;
extern crate mongodb;

#[macro_use] 
extern crate serde_derive;

mod db;
mod appstate;
mod web;

fn main() {
    let db_host = "192.168.0.2";
    let db_port = 32770;

//    let db_host = "localhost";
//    let db_port = 27017;

    db::hello(db_host,db_port);

    let connection = db::Connection::new(db_host,db_port).expect("could not connect to mongo");
    let app = appstate::AppState::new(connection);
    web::kickstart(app);
}
