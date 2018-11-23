
extern crate rss;
extern crate atom_syndication;
extern crate reqwest;
extern crate stringreader;

#[macro_use(serialize_tools)]
extern crate qpy_core;

extern crate ammonia;
extern crate scraper;

use rss::Channel;
use std::io::{Read, BufRead, BufReader};
use atom_syndication::Feed;


const ATOM : &'static str = "http://eclepticaplumb.blogspot.com/feeds/posts/default";
const RSS : &'static str = "https://www.tabletopgamingnews.com/feed";

fn main() {
    let db_host = "192.168.0.2";
    let db_port = 27017;

    qpy_core::db::hello(db_host, db_port);

    //let feed = reqwest::get(ATOM).unwrap().text().unwrap();
    let feed = reqwest::get(ATOM).unwrap().text().unwrap();

//  println!("{}", feed);

    {
        let streader = stringreader::StringReader::new(feed.as_str());
        let bufreader = BufReader::new(streader);

        match Feed::read_from(bufreader){
            Ok(feed) =>{
                for entry in feed.entries(){
                    println!("{}", entry.title());
                    println!("  summary: {}", entry.summary().unwrap_or_default());
                    let content = entry.content().unwrap().value().unwrap_or_default();

                    let selector = scraper::Selector::parse("img").unwrap();
                    let ashtml = scraper::Html::parse_document(content);

                    println!("  imgs:");
                    for element in ashtml.select(&selector) {
                        println!("     {:?}", element.value().attr("src"));
                    }

                    let content = ammonia::clean(content);
                    let content = content.split(' ').take(100).fold("".to_string(), |acc, s| format!("{} {}", acc, s) );
                    println!("  content: {} ...", content);

                    let link = entry.links().split_last();

                    // seems that the last one is the link to the article
                    match link {
                        None => {},
                        Some((l, _)) => {println!(" {}", l.href()); },
                    }
                }
                return;
            },

            Err(_) => {}
        }
    }
    {
        let streader = stringreader::StringReader::new(feed.as_str());
        let bufreader = BufReader::new(streader);

        match rss::Channel::read_from(bufreader){
            Ok(feed) =>{
                for entry in feed.items(){
                    println!("{:?}", entry.title());
                }
                return;
            },

            Err(_) => {}
        }
    }
}
