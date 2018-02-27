#include "dmx_custom_functions.h"
#include <math.h>


static const char* hex_lookup = "0123456789ABCDEF";

DMX_CUSTOM_FUNCTION(String2Hex, DMX_STRING(Hex_Out), DMX_STRING(Str_In)) {
    
	int in_len = Str_In.length();
	
	char buf[2];
	
	Hex_Out.reserve(in_len *2);
	
	for (int i = 0; i < in_len; i++) {
		char c = Str_In.at(i);
		
		char h1 = hex_lookup[(c >> 4) & 0x0F];
		char h2 = hex_lookup[c & 15];
		
		Hex_Out.push_back(h1);
		Hex_Out.push_back(h2);
		
	}
	
    return DMX_CUSTOM_FUNCTION_SUCCESS;
}




// DMX_CUSTOM_FUNCTION(Hex2String, DMX_STRING(Str_Out), DMX_STRING(Hex_In)) {
    // output = "Hello World!";
    // return DMX_CUSTOM_FUNCTION_SUCCESS;
// }

// DMX_CUSTOM_FUNCTION(Hex2Number, DMX_NUMBER(Num_Out), DMX_STRING(Hex_In)) {
    // output = "Hello World!";
    // return DMX_CUSTOM_FUNCTION_SUCCESS;
// }

// DMX_CUSTOM_FUNCTION(Number2Hex, DMX_STRING(Hex_Out), DMX_NUMBER(Num_In)) {
    // output = "Hello World!";
    // return DMX_CUSTOM_FUNCTION_SUCCESS;
// }

