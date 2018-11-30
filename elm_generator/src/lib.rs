#[macro_use]
extern crate quote;
#[macro_use]
extern crate syn;
extern crate itertools;

extern crate proc_macro;

use itertools::Itertools;
use proc_macro::TokenStream;
use std::env;
use std::fs::{remove_file, DirBuilder, File};
use std::io::prelude::*;
use std::path::Path;
use syn::visit::Visit;

// ===============================================================================
// ===============================================================================

trait GenCode {
    fn to_elm(&self) -> String;
    fn elm_encode(&self) -> String;
    fn elm_decode(&self) -> String;
}

type Field = (String, ElmType);

#[derive(Clone, Debug)]
struct ElmStruct {
    name: String,
    fields: Vec<Field>,
}
impl GenCode for ElmStruct {
    fn to_elm(&self) -> String {
        let fields = itertools::join(
            self.fields
                .iter()
                .map(|(n, t)| format!("{}: {}", n, t.to_elm())),
            ",\n    ",
        );

        format!("type alias {} = {{\n   {} \n   }} ", self.name, fields)
    }

    fn elm_encode(&self) -> String {
        let fields = itertools::join(
            self.fields.iter().map(|(n, t)| {
                format!(
                    r#"("{}", {} val.{})"#,
                    n,
                    t.elm_encode(),
                    n
                )
            }),
            ",\n    ",
        );

        format!(
            r#"
encode: {} -> E.Value
encode val =
    object
    [ {} ]
        "#,
            self.name, fields
        )
    }

    fn elm_decode(&self) -> String {
        let n = self.fields.len();
        let fields = itertools::join(
            self.fields.iter().map(|(n, t)| {
                format!(
                    r#"(D.field "{}" {})"#,
                    n,
                    t.elm_decode(),
                )
            }),
            "\n    ",
        );

        format!(
            r#"
decode : D.Decoder {}
decode =
  map{} {}
    {}
"#,
            self.name, n, self.name, fields
        )
    }
}

// ===============================================================================
// ===============================================================================

#[derive(Clone, Debug)]
enum ElmType {
    NotAType,
    Struct(ElmStruct),
    List(Box<ElmType>),
    Maybe(Box<ElmType>),
    Custom(String),
    Native(&'static str),
}

impl ElmType {
    fn to_string(&self) -> String {
        match self {
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.name.clone(),
            ElmType::List(s) => format!("List {}", s.to_string()),
            ElmType::Maybe(s) => format!("Maybe {}", s.to_string()),
            ElmType::Custom(s) => s.clone(),
            ElmType::Native(s) => s.to_string(),
        }
    }
    fn name(&self) -> String {
        match self {
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.name.clone(),
            ElmType::List(s) => "List".to_string(),
            ElmType::Maybe(s) => "Maybe".to_string(),
            ElmType::Custom(s) => s.clone(),
            ElmType::Native(s) => s.to_string(),
        }
    }
}

impl GenCode for ElmType {
    fn to_elm(&self) -> String {
        match self {
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.to_elm(),
            ElmType::List(s) => format!("(List {})", s.to_elm()),
            ElmType::Maybe(s) => format!("(Maybe {})", s.to_elm()),
            ElmType::Custom(s) => s.to_string(),
            ElmType::Native(s) => s.to_string(),
        }
    }
    fn elm_encode(&self) -> String {

        let nullable = |x: String| format!(r#"\x -> 
                case x of
                    Nothing -> E.null
                    Just elem -> elem |> {}
        "#, x);

        match self {
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.elm_encode(),
            ElmType::List(s) => format!("({} {})", 
                                        map_code(&ElmType::List(s.clone()), "E"),
                                        map_code(&s, "E")),
            ElmType::Maybe(s) => format!("({})", nullable(s.elm_encode())),
            ElmType::Custom(s) => map_code(&ElmType::Custom(s.clone()), "E"),
            ElmType::Native(s) => map_native_code(s, "E"),
        }
    }
    fn elm_decode(&self) -> String {
        match self {
            ElmType::NotAType => panic!("not a type"),
            ElmType::Struct(s) => s.elm_decode(),
            ElmType::List(s) => format!("({} {})", 
                                        map_code(&ElmType::List(s.clone()), "D"),
                                        s.elm_decode()),
            ElmType::Maybe(s) => format!("(D.nullable {})", s.elm_decode()),
            ElmType::Custom(s) => map_code(&ElmType::Custom(s.clone()), "D"),
            ElmType::Native(s) => map_native_code(s, "D"),
        }
    }
}

#[derive(Debug)]
struct TypeConverter {
    ty: ElmType,
    deps: Vec<String>,
}

impl TypeConverter {
    fn new() -> TypeConverter {
        TypeConverter {
            ty: ElmType::NotAType,
            deps: Vec::new(),
        }
    }

    fn process<'ast>(mut self, ty: &'ast syn::Type) -> TypeConverter {
        self.visit_type(ty);
        self
    }

    fn process_args<'ast>(mut self, ty: &'ast syn::PathSegment) -> TypeConverter {
        self.visit_path_segment(&ty);
        self
    }

    fn to_type(self) -> (ElmType, Vec<String>) {
        (self.ty, self.deps)
    }
}

fn to_string<'ast>(path: &'ast syn::Path) -> String {
    let s = itertools::join(path.segments.iter().map(|seg| seg.ident.to_string()), "::");

    s
}

fn map_code(ty: &ElmType, prefix: &str) -> String {
    match ty {
        ElmType::NotAType => panic!("not a type"),
        ElmType::Struct(s) => panic!(""),
        ElmType::List(s) => format!("{}.list", prefix),
        ElmType::Maybe(s) => panic!("need to implement maybe"),
        ElmType::Custom(s) => {
            let f = match prefix{
                "E" => "encode",
                "D" => "decode",
                _ => panic!("not a valid prefix"),
            };
            format!("Gen.{}.{}",s, f)
        }
        ElmType::Native(s) => map_native_code(s, prefix),
    }
}

fn map_native_code<'ast>(ty: &str, prefix: &str) -> String {

    format!("{}.{}", prefix,
    match ty {
        "String" => "string",
        "Int" => "int",
        "Float" => "float",
        "Bool" => "bool",

        _ => panic!("not implemented"),
    })
}

fn to_primitive<'ast>(ty: &'ast syn::Path) -> Option<ElmType> {
    let tyName = to_string(&ty);
    match tyName.as_str() {
        "String" => Some(ElmType::Native("String")),
        "str" => Some(ElmType::Native("String")),

        "u8" => Some(ElmType::Native("Int")),
        "u16" => Some(ElmType::Native("Int")),
        "u32" => Some(ElmType::Native("Int")),
        "u64" => Some(ElmType::Native("Int")),

        "i8" => Some(ElmType::Native("Int")),
        "i16" => Some(ElmType::Native("Int")),
        "i32" => Some(ElmType::Native("Int")),
        "i64" => Some(ElmType::Native("Int")),

        "f32" => Some(ElmType::Native("Float")),
        "f64" => Some(ElmType::Native("Float")),

        "bool" => Some(ElmType::Native("Bool")),
        _ => None,
    }
}

impl<'ast> syn::visit::Visit<'ast> for TypeConverter {

    fn visit_derive_input(&mut self, di: &'ast syn::DeriveInput) {
        let mut tc = TypeConverter::new();
        tc.visit_data(&di.data);
        if let (ElmType::Struct(tmpstr), deps) = tc.to_type() {
            self.ty = ElmType::Struct(ElmStruct {
                name: di.ident.to_string(),
                fields: tmpstr.fields,
            });
            self.deps =  deps;
            return;
        }
        panic!("not a struct type");
    }

    fn visit_data_struct(&mut self, ds: &'ast syn::DataStruct) {
        //println!("data struct: {:?}", ds);

        let mut fc: FieldConverter = Default::default();
        for field in ds.fields.iter() {
            fc.visit_field(field);
        }

        self.ty = ElmType::Struct(ElmStruct {
            name: "not just yet".to_string(),
            fields: fc.fields,
        });

        self.deps = fc.deps;
    }

    fn visit_type_path(&mut self, ty: &'ast syn::TypePath) {
        //println!("visit_type_path: {:?}", ty);

        if let Some(ty) = to_primitive(&ty.path) {
            self.ty = ty;
            return;
        }

        let mut segit = ty.path.segments.iter();
        loop {
            let seg = segit.next();
            if seg.is_none() {
                panic!("not cool");
            }
            let seg = seg.unwrap();

            match seg.ident.to_string().as_str() {
                "std" => continue,
                "Vec" => {
                    let next_seg = ty
                        .path
                        .segments
                        .iter()
                        .next()
                        .expect("vec must have a inner type");
                    let (inner_ty, deps) = TypeConverter::new().process_args(next_seg).to_type();
                    self.ty = ElmType::List(Box::new(inner_ty));
                    self.deps = deps;
                    return;
                }
                "Option" => {
                    let next_seg = ty
                        .path
                        .segments
                        .iter()
                        .next()
                        .expect("vec must have a inner type");
                    let (inner_ty, deps) = TypeConverter::new().process_args(next_seg).to_type();
                    self.ty = ElmType::Maybe(Box::new(inner_ty));
                    self.deps = deps;
                    return;
                }
                ident => {
                    // we found a segment which is not know, lets hope is a type defined somewhere else
                    if let Some(_) = segit.next(){
                        panic!("could not convert type");
                    }
                    // get ident as use it as custom type.
                    self.ty = ElmType::Custom(ident.to_string());
                    self.deps.push(ident.to_string());
                    return;
                }
            }
        }
    }
}

#[derive(Default)]
struct FieldConverter {
    fields: Vec<Field>,
    deps: Vec<String>,
}

impl<'ast> syn::visit::Visit<'ast> for FieldConverter {
    fn visit_field(&mut self, field: &'ast syn::Field) {
        if let Some(ref name) = field.ident {
            let (ty, mut deps) = TypeConverter::new().process(&field.ty).to_type();
            self.fields.push((name.to_string(), ty));
            self.deps.append(&mut deps);
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

    let expanded = quote! {};

    TokenStream::from(expanded)
}

fn parse_type(di: syn::DeriveInput) -> (ElmType, Vec<String>) {
    let mut tc = TypeConverter::new();
    tc.visit_derive_input(&di);
    (tc.ty, tc.deps)
}

fn generate_elm_code(di: syn::DeriveInput) {

    let folder = {
        let p = match env::var("ELM_SRC_DIR") {
            Ok(p) => p,
            Err(_) => env::var("CARGO_MANIFEST_DIR").expect("the variable must exist"),
        };

        format!("{}/Gen/", p)
    };
    let (ty, deps) = parse_type(di);
    let file = format!("{}/{}.elm", folder, ty.name());


    let folder = Path::new(folder.as_str());
    let file = Path::new(file.as_str());

    if !folder.exists() {
        DirBuilder::new()
            .recursive(true)
            .create(folder)
            .expect("must go");
    }
    if file.exists() {
        remove_file(file).expect("rewriting file failure");
    }

    let mut file = File::create(file).expect("could not create file");

    let header = format!(
        "module Gen.{} exposing ({}, encode, decode)",
        ty.name(),
        ty.name()
    );
    let import = r#"
import Json.Decode as D exposing (..)
import Json.Encode as E exposing (..)
"#;

    file.write_all(header.as_bytes());
    file.write_all(b"\n");
    file.write_all(import.as_bytes());

    for dep in deps.iter().dedup(){
        let imp = format!("import Gen.{} exposing (..)", dep);
        file.write_all(imp.as_bytes());
        file.write_all(b"\n");
    }

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
        "#,
        )
        .expect("must be valid code");
        //println!("{:?}", di);

        let (x,_) = parse_type(di);
        println!("{}", x.to_elm());
    }

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
        "#,
        )
        .expect("must be valid code");

        generate_elm_code(di);
    }

    #[test]
    fn parse_vec_n_print() {
        let di: syn::DeriveInput = syn::parse_str(
            r#"
            #[derive(Elm)]
            pub struct SomeData {
                pub list: Vec<i32>,
            }
        "#,
        )
        .expect("must be valid code");
        //println!("{:?}", di);

        let (x,_) = parse_type(di);
        println!("{}", x.to_elm());
    }

    #[test]
    fn generate_vec() {
        let di: syn::DeriveInput = syn::parse_str(
            r#"
            #[derive(Elm)]
            pub struct SomeData {
                pub list: Vec<i32>,
            }
        "#,
        )
        .expect("must be valid code");

        generate_elm_code(di);
    }

    #[test]
    fn parse_nested_n_print() {
        let di: syn::DeriveInput = syn::parse_str(
            r#"
            #[derive(Elm)]
            pub struct Outher {
                pub inn: Inner,
            }
        "#,
        )
        .expect("must be valid code");

        let (x,_) = parse_type(di);
        println!("{}", x.to_elm());
    }
    
    #[test]
    fn generate_custom() {
        let di: syn::DeriveInput = syn::parse_str(
        r#"
            #[derive(Elm)]
            pub struct Outher {
                pub inn: Inner,
                pub list: Vec<Inner>,
            }
        "#,
        )
        .expect("must be valid code");

        generate_elm_code(di);
    }
}
