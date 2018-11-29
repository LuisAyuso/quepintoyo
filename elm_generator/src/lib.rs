
#[macro_use]
extern crate quote;
#[macro_use]
extern crate syn;
extern crate itertools;

extern crate proc_macro;

use proc_macro::TokenStream;
use syn::visit::Visit;
use itertools::Itertools;
use std::env;
use std::fs::{File, DirBuilder, remove_file};
use std::path::Path;
use std::io::prelude::*;


trait GenCode{
    fn to_elm(&self) -> String;
    fn elm_encode(&self) -> String;
    fn elm_decode(&self) -> String;
}

type Field = (String, ElmType);

#[derive(Debug)]
struct ElmStruct{
    name: String,
    fields: Vec<Field>,
}
impl GenCode for ElmStruct{
    fn to_elm(&self) -> String{
        let fields = itertools::join (self.fields.iter().map(|(n,t)| format!("{}: {}", n, t.to_elm() )
        ), ",\n    ");

        format!("type alias {} = {{\n   {} \n   }} ", self.name, fields)
    }

    fn elm_encode(&self) -> String{

        let fields = itertools::join (self.fields.iter().map(|(n,t)| format!(r#"("{}", E.{} val.{})"#, n, map_native_decode(t.to_elm().as_str()), n )
        ), ",\n    ");

        format!(r#"
encode: {} -> E.Value
encode val =
    object
    [ {} ]
        "#, self.name, fields)
    }

    fn elm_decode(&self) -> String{

        let n = self.fields.len();
        let fields = itertools::join (self.fields.iter().map(|(n,t)| 
            format!(r#"(D.field "{}" D.{})"#, n, map_native_decode(t.to_elm().as_str()) )
        ), "\n    ");

    format!(r#"
decode : D.Decoder {}
decode =
  map{} {}
    {}
"#, self.name, n, self.name, fields)
    }

}

#[derive(Debug)]
enum ElmType{
    NotAType,
    Struct(ElmStruct),
    Custom(String),
    Native(&'static str),
}

impl ElmType{
    fn to_string (&self) -> String{
        match self{
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.name.clone(),
            ElmType::Custom(s) => s.clone(),
            ElmType::Native(s) => s.to_string(),
        }
    }
    fn name(&self) -> String{
        match self{
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.name.clone(),
            ElmType::Custom(s) => s.clone(),
            ElmType::Native(s) => s.to_string(),
        }
    }
}

impl GenCode for ElmType{
    fn to_elm(&self) -> String{
        match self{
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.to_elm(),
            ElmType::Custom(s) => s.to_string(),
            ElmType::Native(s) => s.to_string(),
        }
    }
    fn elm_encode(&self) -> String{
        match self{
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.elm_encode(),
            ElmType::Custom(s) => panic!("no way"),
            ElmType::Native(s) => map_native_decode(s),
        }
    }
    fn elm_decode(&self) -> String{
        match self{
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.elm_decode(),
            ElmType::Custom(s) => panic!("no way"),
            ElmType::Native(s) => map_native_decode(s),
        }
    }
}

struct TypeConverter{
    ty: ElmType,
}

impl TypeConverter{
    fn new() -> TypeConverter{
        TypeConverter{
            ty : ElmType::NotAType,
        }
    }

    fn process<'ast>(mut self, ty : &'ast syn::Type) -> TypeConverter{
        self.visit_type(ty);
        self
    }

    fn to_type(self) -> ElmType{
        self.ty
    }
}

fn to_string<'ast>(path: &'ast syn::Path) -> String{

    let s = itertools::join( path.segments.iter().map(|seg| {

        seg.ident.to_string()
    }), "::");

    s
}

fn map_native<'ast>(ty: &str) -> ElmType{

    match ty{
        "String" => ElmType::Native("String"),
        "str" => ElmType::Native("String"),

        "u8" =>  ElmType::Native("Int"),
        "u16" => ElmType::Native("Int"),
        "u32" => ElmType::Native("Int"),
        "u64" => ElmType::Native("Int"),
 
        "i8" =>  ElmType::Native("Int"),
        "i16" => ElmType::Native("Int"),
        "i32" => ElmType::Native("Int"),
        "i64" => ElmType::Native("Int"),

        "f32" =>  ElmType::Native("Float"),
        "f64" => ElmType::Native("Float"),

        _ => panic!("not implemented"),
    }
}

fn map_native_decode<'ast>(ty: &str) -> String{

    match ty{
        "String" => "string".to_string(),
        "Int" =>  "int".to_string(),
        "Float" => "float".to_string(),

        _ => panic!("not implemented"),
    }
}

impl<'ast> syn::visit::Visit<'ast> for TypeConverter{

    fn visit_derive_input(&mut self, di: &'ast syn::DeriveInput){

        let mut tc = TypeConverter::new();
        tc.visit_data(&di.data);
        if let ElmType::Struct(tmpstr) = tc.to_type(){

            return self.ty = ElmType::Struct(ElmStruct{
                name: di.ident.to_string(),
                fields: tmpstr.fields,
            });
        } 
        panic!("not a struct type");
    }

    fn visit_data_struct(&mut self, ds: &'ast syn::DataStruct){
        //println!("data struct: {:?}", ds);

        let mut fc : FieldConverter = Default::default();
        for field in ds.fields.iter(){
            fc.visit_field(field);
        }

        self.ty = ElmType::Struct(ElmStruct{
            name: "not just yet".to_string(),
            fields: fc.fields,
        })
    }

    fn visit_type_path(&mut self, ty: &'ast syn::TypePath){
        let ty = to_string(&ty.path);
        self.ty = map_native(ty.as_str());
    }

    fn visit_path_arguments(&mut self, _i: &'ast syn::PathArguments){

    }

    fn visit_path_segment(&mut self, _i: &'ast syn::PathSegment){

    }

}

#[derive(Default)]
struct FieldConverter{
    fields: Vec<Field>,
}

impl<'ast> syn::visit::Visit<'ast> for FieldConverter{

    fn visit_field(&mut self, field: &'ast syn::Field){
        if let Some(ref name) = field.ident{
            let ty = TypeConverter::new().process(&field.ty).to_type();
            self.fields.push ((name.to_string(), ty));
            return;
        }
        panic!("field: {:?} not supported", field)
    }
}



#[proc_macro_derive(Elm)]
pub fn derive_elm(input: TokenStream) -> TokenStream {
    // Construct a string representation of the type definition
    let di = parse_macro_input!(input as syn::DeriveInput);

    generate_elm_code(di);

    let expanded = quote! {
    };


    TokenStream::from(expanded)
}

fn parse_type(di: syn::DeriveInput) -> ElmType{
    let mut tc = TypeConverter::new();
    tc.visit_derive_input(&di);
    tc.ty
}

fn generate_elm_code(di: syn::DeriveInput){

    let key = "CARGO_MANIFEST_DIR";
    let p = env::var(key).expect("the variable must exist");

    let ty = parse_type(di);
    let folder = format!("{}/elm/Gen/",p);
    let file = format!("{}/elm/Gen/{}.elm",p, ty.name());

    let folder = Path::new(folder.as_str());
    let file = Path::new(file.as_str());

    if !folder.exists(){
        DirBuilder::new().recursive(true).create(folder).expect("must go");
    }
    if file.exists(){
        remove_file(file).expect("rewriting file failure");
    }

    println!("{}", p);
    let mut file = File::create(file).expect("could not create file");
    
    let header = format!("module Gen.{} exposing ({}, encode, decode)", ty.name(), ty.name());
    let import = 
    r#"
import Json.Decode as D exposing (..)
import Json.Encode as E exposing (..)
"#;

    file.write_all(header.as_bytes());
    file.write_all(b"\n");
    file.write_all(import.as_bytes());
    file.write_all(b"\n");
    file.write_all(ty.to_elm().as_bytes());
    file.write_all(b"\n");
    file.write_all(ty.elm_encode().as_bytes());
    file.write_all(b"\n");
    file.write_all(ty.elm_decode().as_bytes());

}



#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn generate() {
        let di: syn::DeriveInput = syn::parse_str(
        r#"
            #[derive(Elm)]
            pub struct UserData {
                pub string: String,
                pub ref_str: &'static str,
                pub int: u32,
                pub float: f32,
            }
        "#).expect("must be valid code");

        generate_elm_code(di);
    }

    #[test]
    fn parse_n_print() {

        let di: syn::DeriveInput = syn::parse_str(
        r#"
            #[derive(Elm)]
            pub struct UserData {
                pub string: String,
                pub ref_str: &'static str,
                pub int: u32,
                pub float: f32,
            }
        "#).expect("must be valid code");
        //println!("{:?}", di);

        let x = parse_type(di);
        println!("{}", x.to_elm());
    }
}
