extern crate atom_syndication;
extern crate reqwest;
extern crate rss;
extern crate stringreader;

#[macro_use(serialize_tools)]
extern crate qpy_core;

extern crate ammonia;
extern crate scraper;

use atom_syndication::Feed;
use rss::Channel;
use std::io::{BufRead, BufReader, Read};

const ATOM: &'static str = "http://eclepticaplumb.blogspot.com/feeds/posts/default";
const RSS: &'static str = "https://www.tabletopgamingnews.com/feed";


fn get_content (content: &str) -> (Vec<String>, String) {

    let selector = scraper::Selector::parse("img").unwrap();
    let ashtml = scraper::Html::parse_document(content);

    println!("  imgs:");
    let mut imgs = Vec::new();
    for element in ashtml.select(&selector) {
        imgs.push(element.value().attr("src").unwrap_or_default());
    }
    let imgs: Vec<String> =
        imgs.iter().filter(|e| e.len() != 0).map(|r| (*r).to_string()).collect();

    let content = ammonia::clean(content);
    let content = content
        .split(' ')
        .take(50)
        .fold("".to_string(), |acc, s| format!("{} {}", acc, s));
    println!("  content: {} ...", content);

    (imgs, content)
}

fn main() {
    let db_host = "192.168.0.2";
    let db_port = 27017;

    qpy_core::db::hello(db_host, db_port);
    let conn = qpy_core::db::Connection::new(db_host, db_port).expect("must connect");


    let feed = reqwest::get(ATOM).unwrap().text().unwrap();
    //let feed = reqwest::get(RSS).unwrap().text().unwrap();

     // println!("{}", feed);

    {
        let streader = stringreader::StringReader::new(feed.as_str());
        let bufreader = BufReader::new(streader);

        match Feed::read_from(bufreader) {
            Ok(feed) => {
                for entry in feed.entries() {
                    let title = entry.title();
                    println!("{}", title);

                    println!("  summary: {}", entry.summary().unwrap_or_default());
                    let content = entry.content().unwrap().value().unwrap_or_default();

                    let (imgs, content) = get_content(content);

                    let link = entry.links().split_last();

                    // seems that the last one is the link to the article
                    match link {
                        None => {}
                        Some((l, _)) => {
                            println!(" {}", l.href());
                        }
                    }

                    use qpy_core::NewsEntry;
                    use qpy_core::conversion::Convert;

                    let entry = NewsEntry {
                        title: title.to_string(),
                        content: content,
                        photos: Some(imgs),
                        link: link.map(|(l,_)| l.href().to_string()),
                    };
                    
                    conn.add_doc("news", entry.to_bson().unwrap()).expect("must add");
                }
                return;
            }

            Err(_) => {}
        }
    }
    {
        let streader = stringreader::StringReader::new(feed.as_str());
        let bufreader = BufReader::new(streader);

        match rss::Channel::read_from(bufreader) {
            Ok(feed) => {
                for entry in feed.items() {
                    println!("{:?}", entry.title());
                    println!("{:?}", entry.source());
                    println!("{:?}", entry.content());
                    println!("{:?}", entry.link());
                    let (imgs, content) = get_content(entry.description().unwrap_or_default());

                    use qpy_core::NewsEntry;
                    use qpy_core::conversion::Convert;
                    let entry = NewsEntry {
                        title: entry.title().unwrap_or_default().to_string(),
                        content: content,
                        photos: Some(imgs),
                        link: entry.link().map(|s| s.to_string())
                    };
                    
                    conn.add_doc("news", entry.to_bson().unwrap()).expect("must add");
                }
                return;
            }

            Err(_) => {}
        }
    }
}
