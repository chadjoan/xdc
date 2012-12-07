module misc;

/* A compile-time evaluatable number->string conversion. */
string itoa(long num)
{
	//__ctfeWriteln("sup!");
	const string digitLookup = "0123456789";
	if ( num < 0 )
		return "-" ~ itoa(-num);
	else if ( num < 10 )
		return [digitLookup[cast(size_t)num]];
	else
		return itoa(num / 10) ~ itoa(num % 10);
}

/* A compile-time evaluatable bool->string conversion. */
string boolToStr(bool val)
{
	if ( val ) return "true";
	else       return "false";
}

void stubAlert(string file = __FILE__, int line = __LINE__)
{
	debug __ctfeWriteln(file~", "~itoa(line)~": stub");
}
