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

    db::hello();
    web::kickstart();
}
