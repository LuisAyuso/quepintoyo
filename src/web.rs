use rocket::data::Data;
use rocket::http::RawStr;
use rocket::http::Status;
use rocket::request::Form;
use rocket::response::NamedFile;
use rocket::State;

use std::process::Command;
use std::str;

use std::ffi::OsStr;
use std::path::{Path, PathBuf};

use crate::conversion::*;
use mongodb::bson;
use serde_json;

use crate::appstate::AppState as App;
use crate::appstate::Token;

// =========================================================

// =========================================================

// const ELM :&'static str =  "C:\\Users\\Luis\\AppData\\Roaming\\npm\\elm.cmd";
const ELM: &'static str = "elm";
const TMP_SCRIPT_FOLDER: &'static str = ".tmp_scripts";

// =========================================================

#[get("/", rank = 2)]
fn index() -> Option<NamedFile> {
    NamedFile::open(Path::new("static/index.html")).ok()
}

// =========================================================

#[derive(Serialize, Deserialize)]
struct FilePortData {
    pub contents: String,
    pub filename: String,
}

// =========================================================

//#[post("/upload", format = "image/*", data = "<data>")]
#[post("/upload", data = "<data>")]
pub fn upload(data: Data) -> Result<String, Status> {
    let peek = data.peek();
    if !data.peek_complete() {
        return Err(Status::InternalServerError);
    }

    if let Ok(content) = str::from_utf8(peek) {
        println!("{}", content);
        let filedata: FilePortData =
            serde_json::from_str(content).map_err(|_| Status::InternalServerError)?;
        println!("{}", filedata.filename);
        println!("{}", filedata.contents);
    }

    Ok("guay".to_string())
}

// =========================================================

use crate::appstate::UserData as Login;

#[post("/login", data = "<data>")]
fn login(data: Form<Login>, state: State<App>) -> Result<String, Status> {
    let data = data.into_inner();

    println!("{:?}", data.user);
    let query: bson::Document = data.to_bson()?;

    let entry = state.db.find_one("users", query)?;
    println!("user entry retrieved");

    let entry = Login::from_bson(entry)?;

    let tok = Token::new(data.user.as_str())?;
    state
        .tokens
        .write()
        .map_err(|_| Status::InternalServerError)?
        .entry(tok.clone())
        .or_insert(entry);
    Ok(tok.to_string())
}

#[post("/register", data = "<data>")]
fn register(data: Form<Login>, state: State<App>) -> Result<String, Status> {
    let data = data.into_inner();

    let query = doc! {
        "username": data.user.clone(),
    };
    let res = state.db.find("users", query);

    match res {
        Err(_) => {
            println!("failed user query!");
            return Err(Status::InternalServerError);
        }

        Ok(cursor) => {
            println!("cursor retrieved");
            if cursor.count() != 0 {
                println!("not empty");
                return Err(Status::MethodNotAllowed);
            }

            let user_entry = bson::to_bson(&data).map_err(|_| Status::InternalServerError)?;
            if let bson::Bson::Document(doc) = user_entry {
                return match state.db.add_doc("users", doc) {
                    Ok(_) => {
                        let tok = Token::new(data.user.clone().as_str())?;
                        state
                            .tokens
                            .write()
                            .map_err(|_| Status::InternalServerError)?
                            .entry(tok.clone())
                            .or_insert(data);
                        Ok(tok.to_string())
                    }
                    Err(_) => Err(Status::InternalServerError),
                };
            }
        }
    }
    Err(Status::Unauthorized)
}

// =========================================================

#[get("/<file..>", rank = 1)]
fn static_files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("static/").join(file)).ok()
}

// =========================================================

fn compile(elmpath: &Path, jspath: &Path) -> Result<(), Status> {
    // compile
    let inarg = format!("{}", elmpath.to_str().ok_or(Status::NotAcceptable)?);
    let outarg = format!("--output={}", jspath.to_str().ok_or(Status::NotAcceptable)?);

    let output = Command::new(ELM)
        .args(&["make", inarg.as_str(), "--debug", outarg.as_str()])
        .output()
        .map_err(|_| Status::InternalServerError)?;

    if !output.status.success() {
        println!("{}", str::from_utf8(output.stdout.as_slice()).unwrap());
        println!("{}", str::from_utf8(output.stderr.as_slice()).unwrap());
        return Err(Status::InternalServerError);
    }

    Ok(())
}

#[get("/scripts/<scriptfile>")]
fn script(scriptfile: &RawStr) -> Result<NamedFile, Status> {
    let jspath = Path::new(TMP_SCRIPT_FOLDER).join(scriptfile.to_string());

    // asking for a js script
    if jspath.extension() != Some(OsStr::new("js")) {
        return Err(Status::NotAcceptable);
    }

    // convert extension into elm, and check that file exists
    let mut elmfile = jspath
        .file_stem()
        .ok_or(Status::NotAcceptable)?
        .to_os_string();
    elmfile.push(OsStr::new(".elm"));
    let elmpath = Path::new("elm/").join(elmfile);

    if !elmpath.exists() {
        return Err(Status::NotFound);
    }

    // compile
    compile(&elmpath, &jspath)?;

    // return
    NamedFile::open(jspath).map_err(|_| Status::InternalServerError)
}

// =========================================================

#[get("/check_token")]
fn check_token(token: Token) -> Result<String, Status> {
    Ok(token.to_string())
}

// =========================================================

#[put("/jobs")]
fn put_jobs(token: Token) -> Result<String, Status> {
    Ok(token.to_string())
}

#[get("/jobs")]
fn get_jobs(token: Token, state: State<App>) -> Result<String, Status> {

    let query = doc! {
        "username": token.get_user_name()?
    };
    let cursor = state.db.find("users", query)?;

    use crate::appstate::Job;

    let docs: Vec<Job> = cursor
        .filter(|elem| elem.is_ok())
        .map(|elem| {
            let e = elem.unwrap();
            Job::from_bson(e).unwrap()
        })
        .collect();

    Ok("".to_string())
}

// =========================================================

#[put("/news")]
fn put_news(token: Token) -> Result<String, Status> {
    Ok(token.to_string())
}

#[get("/news")]
fn get_news(token: Option<Token>, state: State<App>) -> Result<String, Status> {

//    let query = doc! {
//        "username": token.get_user_name()?
//    };
//    let cursor = state.db.find("users", query)?;
//
//    use crate::appstate::Job;
//
//    let docs: Vec<Job> = cursor
//        .filter(|elem| elem.is_ok())
//        .map(|elem| {
//            let e = elem.unwrap();
//            Job::from_bson(e).unwrap()
//        })
//        .collect();

    Ok("".to_string())
}

#[get("/news/<id>")]
fn get_news_single(id: &RawStr, token: Option<Token>, state: State<App>) -> Result<String, Status> {
    Ok("".to_string())
}

// =========================================================

pub fn kickstart(app: App) {
    rocket::ignite()
        .manage(app)
        .mount(
            "/",
            routes![
                index,
                static_files,
                script,
                upload,
                login,
                register,
                check_token,
                get_jobs,
                put_jobs,
                get_news,
                put_news,
                get_news_single,
            ],
        )
        .launch();
}
