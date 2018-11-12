#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] 
extern crate rocket;
use rocket::http::RawStr;
use rocket::http::Status;
use rocket::response::NamedFile;

use std::process::Command;
use std::str;

use std::path::{Path, PathBuf};
use std::ffi::{OsStr};


#[get("/")]
fn index() -> Option<NamedFile> {
    NamedFile::open(Path::new("static/index.html")).ok()
}

const ELM :&'static str =  "C:\\Users\\Luis\\AppData\\Roaming\\npm\\elm.cmd";
const TMP_SCRIPT_FOLDER: &'static str =  ".tmp_scripts";

fn compile (elmpath: &Path, jspath: &Path) -> Result<String, Status> {
    // compile
    let inarg = format!("{}", elmpath.to_str().ok_or(Status::NotAcceptable)?);
    let outarg = format!("--output={}", jspath.to_str().ok_or(Status::NotAcceptable)?);

    let output = Command::new(ELM)
                    .args(&["make", inarg.as_str(), "--debug", outarg.as_str()])
                    .output()
                    .map_err(|_| Status::InternalServerError)?;
    
    if !output.status.success()
    {
        println!("{}", str::from_utf8(output.stdout.as_slice()).unwrap());
        println!("{}", str::from_utf8(output.stderr.as_slice()).unwrap());
        return Err(Status::InternalServerError);
    }

    Ok("great".to_string())
}

#[get("/scripts/<file>")]
fn elm(file: &RawStr) -> Result<NamedFile, Status> {

    let jspath = Path::new(TMP_SCRIPT_FOLDER).join(file.to_string());

    // asking for a js script
    if jspath.extension() != Some(OsStr::new("js"))
    {
        return Err(Status::NotAcceptable);
    }

    // convert extension into elm, and check that file exists
    let mut elmfile = jspath.file_stem().ok_or(Status::NotAcceptable)?.to_os_string();
    elmfile.push(OsStr::new(".elm"));
    let elmpath = Path::new("elm/").join(elmfile);

    if !elmpath.exists()
    {
        return Err(Status::NotFound);
    }

    // compile
    compile(&elmpath, &jspath)?;

    // return
    NamedFile::open(jspath).map_err(|_| Status::InternalServerError)
}

fn main() {
    rocket::ignite()
            .mount("/", routes![index, elm])
            .launch();
}
