module i18nc3;
import std::io;
import std::io::file;
import std::os;
import std::core::mem::allocator;
import std::collections::map;
import std::collections::object;
import std::encoding::json;

alias LanguageMap = HashMap{String, Object*};
alias TranslationMap = HashMap{String, LanguageMap};

faultdef LANGUAGE_MAP_ALREADY_EXIST, LANGUAGE_MAP_NOT_FOUND;

// TODO 
// Implement Translator.load to load all .json files from directory as LanguageMap.
// This requires iterating over the directory and loading each file.

// TODO 
// Implement pluralization support.

// TODO 
// Implement variable interpolation support.

struct Translator (Printable) {
	Allocator allocator;
	TranslationMap tmap;
	String currentLanguage;
}

fn Translator new_translator(Allocator allocator, String currentLanguage = "en") {
	Translator t;
	t.allocator = allocator;
	t.tmap.init(allocator);
	t.currentLanguage = currentLanguage;
	return t;
}

fn void? Translator.load_from_json(&self, String file_path, String code) {
	String file_content = (String) file::load(self.allocator, file_path)!;
	Object* object = json::parse_string(self.allocator, file_content)!;

	if (self.tmap.has_key(code)) {
		return LANGUAGE_MAP_ALREADY_EXIST?;
	}

	self.tmap.set(code, object.map);
}

fn void? Translator.set_language(&self, String code) {
	if (!self.tmap.has_key(code)) {
		return LANGUAGE_MAP_NOT_FOUND?;
	}
	
	self.currentLanguage = code;
}

fn Object*? Translator.translate(&self, String key) {	
	if (try LanguageMap lmap = self.tmap.get(self.currentLanguage)) {
		return lmap.get(key)!!;
	}

	return LANGUAGE_MAP_NOT_FOUND?;
}

fn int main(String[] args)
{
	Allocator allocator = allocator::heap();
	Translator translator = new_translator(allocator);

	if (catch excuse = translator.load_from_json("./examples/locales/en.json", "en")) {
		io::printfn("Error loading JSON: %s\n", excuse);
	}

	if (catch excuse = translator.load_from_json("./examples/locales/fa.json", "fa")) {
		io::printfn("Error loading JSON: %s\n", excuse);
	}

	translator.set_language("fa")!!;

	io::printfn("Current Language: %s", translator.currentLanguage);

	Object* greeting = translator.translate("greeting")!!;
	io::printfn("- Greeting: %s", greeting);

	Object* farewell = translator.translate("farewell")!!;
	io::printfn("- farewell: %s", farewell);

	return 0;
}