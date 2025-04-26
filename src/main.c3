module std::text::i18n;
import std::io;
import std::io::file;
import std::os;
import std::core::mem::allocator;
import std::collections::map;
import std::collections::object;
import std::collections::list;
import std::encoding::json;
import std::time;

alias LanguageMap = HashMap{String, Object*};
alias LoadedFilesList = List{Object*};
alias TranslationMap = HashMap{String, LanguageMap};

// This fault raised when translation key not found.
faultdef NOT_FOUND;

struct Translator (Printable) {
	Allocator allocator;
	TranslationMap tmap;
	String currentLanguage;
	LoadedFilesList loadedFiles;
}

fn Translator new_translator(Allocator allocator, String currentLanguage = "en") {
	Translator t;
	t.allocator = allocator;
	t.tmap.init(allocator);
	t.currentLanguage = currentLanguage;
	t.loadedFiles.init(allocator);
	return t;
}

fn void Translator.free(&self) {
	foreach (Object* object : self.loadedFiles)
	{
		object.free();
	}

	self.tmap.free();
	self.loadedFiles.free();
}

fn void? Translator.load_from_json(&self, String file_path, String code) {
	String file_content = (String) file::load(self.allocator, file_path)!;
	defer file_content.free(self.allocator);

	Object* object = json::parse_string(self.allocator, file_content)!;

	if (self.tmap.has_key(code)) {
		return io::ALREADY_EXISTS?;
	}

	self.tmap.set(code, object.map);
	self.loadedFiles.push(object);
}

fn void? Translator.set_language(&self, String code) {
	if (!self.tmap.has_key(code)) {
		return io::FILE_NOT_FOUND?;
	}
	
	self.currentLanguage = code;
}

macro Translator.tr(&self, key, ...) {
	if (try LanguageMap lmap = self.tmap.get(self.currentLanguage)) {
		Object* object = lmap.get(key)!;

		if (!object.is_string()) {
			return io::UNSUPPORTED_OPERATION?;
		}

		return string::format(self.allocator, object.s, $vasplat[..]);
	}

	return NOT_FOUND?;
}

fn int main(String[] args)
{
	Allocator allocator = allocator::heap();
	Translator translator = new_translator(allocator);
	defer translator.free();

	if (catch excuse = translator.load_from_json("./examples/locales/en.json", "en")) {
		io::printfn("Error loading JSON: %s\n", excuse);
	}

	if (catch excuse = translator.load_from_json("./examples/locales/fa.json", "fa")) {
		io::printfn("Error loading JSON: %s\n", excuse);
	}

	translator.set_language("en")!!;

	io::printfn("Current Language: %s", translator.currentLanguage);

	String greeting = translator.tr("greeting", "C3")!!;
	defer greeting.free(allocator);
	io::printfn("- Greeting: %s", greeting);

	String farewell = translator.tr("farewell", "C3")!!;
	defer farewell.free(allocator);
	io::printfn("- farewell: %s", farewell);

	return 0;
}

	