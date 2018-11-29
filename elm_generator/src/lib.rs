
#[macro_use]
extern crate quote;
#[macro_use]
extern crate syn;
extern crate itertools;

extern crate proc_macro;

use proc_macro::TokenStream;
use syn::visit::Visit;
use itertools::Itertools;
use std::collections::BTreeMap as Map;

type Field = (String, ElmType);

#[derive(Debug)]
struct ElmStruct{
    name: String,
    fields: Vec<Field>,
}

#[derive(Debug)]
enum ElmType{
    None,
    Struct(ElmStruct),
    Custom(String),
    Native(&'static str),
}


#[derive(Default)]
struct ConvertCtx{
    type_alias: Map<String, ElmType>,
}

impl ConvertCtx{
    fn new () -> ConvertCtx{
        Default::default()
    }
}


struct TypeConverter{
    ty: ElmType,
}

impl TypeConverter{
    fn new() -> TypeConverter{
        TypeConverter{
            ty : ElmType::None,
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

    println!("map {}", ty);
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

        _ => panic!("not implemtned"),
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
        println!("data struct: {:?}", ds);

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

    fn visit_path_arguments(&mut self, i: &'ast syn::PathArguments){

    }

    fn visit_path_segment(&mut self, i: &'ast syn::PathSegment){

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

    println!("one elm struct found");

    TokenStream::from(expanded)
}

fn parse_types(di: syn::DeriveInput) -> ElmType{
    let mut tc = TypeConverter::new();
    tc.visit_derive_input(&di);
    tc.ty
}

fn generate_elm_code(di: syn::DeriveInput){

    parse_types(di);
}


#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn it_works() {

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
        println!("{:?}", di);

        let x = parse_types(di);
        println!("{:?}", x);
    }
}
