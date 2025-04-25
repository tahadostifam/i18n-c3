module c3examples;
import std::io;
import std::io::file;
import std::os;
import std::core::mem::allocator;
import std::collections::map;
import std::collections::object;
import std::encoding::json;

alias LanguageMap = HashMap{String, String};
alias TranslationMap = HashMap{String, LanguageMap};

faultdef LANGUAGE_MAP_ALREADY_EXIST;

struct Translator (Printable) {
	Allocator allocator;
	TranslationMap tmap;
}

fn Translator new_translator(Allocator allocator) {
	Translator t;
	t.allocator = allocator;
	t.tmap.init(allocator);
	return t;
}

fn void? Translator.add_translation(&self, String code, LanguageMap map) @private {
	if (self.tmap.has_key(code)) {
		return LANGUAGE_MAP_ALREADY_EXIST?;
	}

	self.tmap.set(code, map);
}

fn void Translator.load_from_json(&self, String file_path) {
	String file_content = (String) file::load(self.allocator, file_path)!!;
	Object* obj = json::parse_string(self.allocator, file_content)!!;
	
	// FIXME
	// How to convert Object to HashMap?
}

fn int main(String[] args)
{
	Allocator allocator = allocator::heap();
	Translator translator = new_translator(allocator);

	translator.load_from_json("./examples/locales/en.json");


	return 0;
}