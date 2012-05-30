import std.stdio;
import std.array;
import std.string;
import std.conv;
import object;


private enum JSONFieldType{
	NUMERIC,
	STRING,
	ARRAY,
	JSON

}

private struct JSONValue{
	char[] value;
	JSONFieldType type;		

}


/**
 * A class used to represent a JSON object 
 */
public class JSON{
	
	private JSONValue[string] fields;
	

	
	/**
	 * Construct a new JSON object from the given string.
	 */
	public this(string jsonstring){
		this(cast(char[])(jsonstring));
	}
	
	/**
	 * Construct a new JSON object from the given string
	 */
	public this(char[] jsonstring){
		char[][] fields = getFields(jsonstring);
		foreach(char[] pair; fields){

			//writefln("we are treating a key: %s", pair);
			pair = strip(pair); // get rid of any whitespace.
			char[][] keyValue = getKeyValuePair(pair);
			
			// we have the key and value strings, now we'll figure out the type of the value..
			char[] key = stripQuotes(keyValue[0]);
			JSONValue jsonPair;
			char[] storevalue = keyValue[1];
			
			
			char first = storevalue[0];
			if(first == '"'){  
				jsonPair.type = JSONFieldType.STRING; 
				jsonPair.value = stripQuotes(storevalue);
			}  
			
			else if(first == '['){ 
				jsonPair.type = JSONFieldType.ARRAY; 
				jsonPair.value = storevalue; // don't treat it. It's an array that we'll parse later if need be.
			}
			else if(first == '{'){ 
				jsonPair.type = JSONFieldType.JSON; 
				jsonPair.value = storevalue;
			}
			else{ // default is number.
				jsonPair.type = JSONFieldType.NUMERIC;
				jsonPair.value = stripQuotes(storevalue);
			}
				

			
			//writefln("storing key=%s in value=%s", key, jsonPair.value);
			this.fields[cast(string)(key)] = jsonPair;
	
		}
		
		

	
	}




	public void extend(string key, double value){
		JSONValue v;
		char[] sValue = cast(char[])(format("%f", value));
		v.type = JSONFieldType.NUMERIC;
		v.value = sValue;
		fields[key] = v;
	}
 

 	public void extend(string key, int value){
		JSONValue v = {
			type: JSONFieldType.NUMERIC,
			value: cast(char[])(format("%d", value))
		};
		fields[key] = v;
	}

	public void extend(string key, string value){
		JSONValue v = {
			type: JSONFieldType.STRING,
			value: cast(char[])(value)
		};
		fields[key] = v;
	}



	public string[] getKeys(){
		return fields.keys;
	}
	
	/**
	 * splits up a string in the form of a JSON key value pair into two
	 * strings. The first is the key and second is the value. Both are uncasted.
	 */
	private char[][] getKeyValuePair(char[] jsonPair){
		int colonIndex = 0;
		for(int i = 0 ; i < jsonPair.length; i++){
			if(jsonPair[i] == ':'){
				return [ jsonPair[0 .. i] , jsonPair[i+1 .. $] ];
			}
		}
		// throw an exception here.
		return [];
	}
	
	
	/**
	 * split up a JSON string into it's top-level values.
	 */
	private char[][] getFields(char[] jsonstring){
		jsonstring = strip(jsonstring); // get rid of whitespace.
		int length = jsonstring.length;	
		
		// strip the JSON string of it's encapsulating curly braces.
		jsonstring = jsonstring[1 .. ($ - 1)];
		//writefln("the jsonstring with it's curly braces removed:\n%s", jsonstring);
				
		
		char[][] pairs;

		// we need to keep track of the number of closing and opening
		// curly braces so we know when to count delimiting commas.
		int depth = 0;
		int pairOffset = 0;		

		foreach(int i, char c; jsonstring){
			if(c == '{' || c == '[') { depth++;  /+ writefln("at character: %d we found an opening", i); +/  }			
			if(c == '}' || c == ']') { depth--;  /+ writefln("at character: %d we found a closing", i); +/ }
			
			if(c == ',' && depth == 0){
				pairs ~= [ jsonstring[pairOffset .. i]  ];
				pairOffset = i + 1;
			}
		}

		// get the last element.
		pairs ~= strip(jsonstring[pairOffset .. (jsonstring.length)]);
		
		return pairs; 
	}

	/** 
	 * Strip outer quotes from the given string. 
	 * This is useful for turning keys or string values into raw literals. 
	 */
	private char[] stripQuotes(char[] str){
		str = strip(str);
		if(str[0] == '"' && str[str.length - 1] == '"'){
			return str[1 .. str.length - 1];
		}else{
			// throw an exception
			return str;
		}
	}


	/**
	 * Reads the JSON at the given key and returns the value as a string.
	 *
	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * a string.
	 */
	public string getString(string key){
		if(!(key in fields)){
			throw new JSONParseException("The data at \"" ~ key ~ "\" was not found in the JSON object.");
		
		}else{
			return cast(string)(fields[key].value);
		}
	}

	/**
	 * Reads the JSON at the given key and returns the value as an int.
	 *
   	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * an int.
	 */
	public int getInt(string key){
		return to!int(fields[key].value);	
	}

	
	/**
	 * Reads the JSON at the given key and returns the value as a double. 
	 *
	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * a double.
	 */
	public double getDouble(string key){
		return to!double(fields[key].value);				
	}


	public JSON getJSON(string key){
		return new JSON(fields[key].value);
	}

	
	/**
	 * checks to see if a given key is the JSON object 
	 * @param key the key for the JSON object.
	 */
	public bool checkForKey(string key){
		return cast(bool)(key in fields);	
	}



	/**
	 * Gets the string array the the given key
	 *
	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * a string.
	 */
	public string[] getStringArray(string key){
		
		// get the element
		JSONValue element = fields[key];

		// get the string representation of the array which we have to parse.	
		char[] arrString = element.value; 
		arrString = strip(arrString);
		
		// get rid of the square brackets and split into tokens.
		arrString = arrString[1 .. arrString.length - 1];
		char[][] tokens  = split(arrString, ",");
		foreach(int i, char[] value;tokens){
			tokens[i] = stripQuotes(value);
		
		}
		return cast(string[])(tokens);

	}


	/**
	 * Get the double array at the given key.
	 *
	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * a string.
	 */
	public double[] getDoubleArray(string key){
		
		// get an string array representation of the array.
		string[] doubleStrings = getStringArray(key);	

		

		// now loop throught the strings and convert to doubles.
		double[] doubles = new double[doubleStrings.length];
		foreach(int i, string s; doubleStrings){
			//writefln("attempting to return: %s", s);
			doubles[i] = to!double(s);
		}
		return doubles;
	}



	/**
	 * Get the int array at the given key.
	 * 
	 * Throws a JSONParseException is the data being retrieved is not in fact
	 * a string.
	 */
	public int[] getIntArray(string key){
		string[] stringArr = getStringArray(key);
		int[] intArr = new int[stringArr.length];

		foreach(int i, string s; stringArr){
			intArr[i] = s.to!int(); //std.conv.toInt(s);
		}

		return intArr;
	}


}

/** custom exception class for lazy json. */
private class JSONParseException : Exception{
	public this(string msg){
		super(msg);
	}
}




void main(){
	// empty main method that doesn't do anything.		
}

unittest{

	writefln("beginning unittest for lazyjson.d\n\n");
	
	writefln("Test 1.0--parsing");
	string jsonstring = "{\"name\":\"Lee Avital\", \"siblings\":[\"Lori\", \"Abigail\"]}";
	writefln("We are parsing the string: %s", jsonstring);
	JSON j = new JSON(jsonstring);
	if(j) writefln("success!\n");
	else writefln("failure\n");

	writef("Test 1.1: shallow retrieval...");
	string name = j.getString("name");
	if(name == "Lee Avital"){ writef("success!\n"); }
	else{ writef("failure\n"); }

	writef("Test 1.2: mid-level retrieval...");
	string[] siblings = j.getStringArray("siblings");
	if(siblings[0] == "Lori" && siblings[1] == "Abigail"){ writef("success!\n"); }
	else{ writef("failure\n"); }

	
	writef("Test 1.3: shallow extending...");
	j.extend("mynum", 2);
	if(j.getDouble("mynum") == 2){  writef("success\n"); }
	else{ writef("failure\n"); }
	

	writef("Test 1.4: deep extending...");
	j.extend("myarr", "[2,3,4]");
	int[] arr = j.getIntArray("myarr");
	if(arr[0] == 2 && arr[1] == 3 && arr[2] == 4){
		writef("success\n\n\n");
	}
	else{
		writef("failure\n\n\n");
	}


	jsonstring = "{\"name\":\"My App\", \"permissions\":[\"google.com\", \"facebook.com\"], \"browser_action\":{\"icon\":\"icon.png\", \"caption\":\"click me!\"}}";
	writefln("Test 2.0: parsing");
	writefln("Parsing the string: %s", jsonstring);
	j = new JSON(jsonstring);
	if(j){ writefln("success!\n"); }
	else{ writefln("failure\n"); }

	writef("Test 2.1: shallow retrival...");
	// name already declared.
	name = j.getString("name");
	if(name == "My App"){ writef("success!\n"); }
	else{ writef("failure\n"); }

	
	writef("Test 2.2: mid-level retrival...");
	string[] arr2 = j.getStringArray("permissions");
	if(arr2[0] == "google.com" && arr2[1] == "facebook.com"){
		writef("success!\n");
	}
	else{
		writef("failure\n");
	}


	
	writef("Test 2.3: deep retrival...");
	JSON jLow = j.getJSON("browser_action"); // lol, jay-lo
	if(jLow.getString("icon") == "icon.png" && jLow.getString("caption") == "click me!"){
		writef("success!\n");
	}
	else{
		writef("failure\n");
	}

}
