struct YoDawg(ElemType)
{
	alias Match!ElemType Match;

	Match n0( constchar[] inputRange, size_t cursor, size_t ubound )
	{
		/* Sequence */
		auto m0 = n1(inputRange, cursor, ubound);
		if ( !m0.successful )
			return Match.failure(inputRange);

		return Match.success(inputRange, m0.begin, m0.end);
	}

	Match n1( constchar[] inputRange, size_t cursor, size_t ubound )
	{
		/* Sequence */
		auto m0 = n2(inputRange, cursor, ubound);
		if ( !m0.successful )
			return Match.failure(inputRange);

		auto m1 = n3(inputRange, m0.end, ubound);
		if ( !m1.successful )
			return Match.failure(inputRange);

		return Match.success(inputRange, m0.begin, m1.end);
	}

	Match n2( constchar[] inputRange, size_t cursor, size_t ubound )
	{
		/* Literal */
		if ( cursor > ubound )
			return Match.failure(inputRange);
		else if ( inputRange[cursor] == x )
			return Match.success(inputRange, cursor, cursor+1);
		else
			return Match.failure(inputRange);
	}

	Match n3( constchar[] inputRange, size_t cursor, size_t ubound )
	{
		/* Maybe */
		/* Ordered Choice */
		auto m0 = n4(inputRange, cursor, ubound);
		if ( m0.successful )
			return Match.success(inputRange, m0.being, m0.end);

		return Match.failure(inputRange);
	}

	Match n4( constchar[] inputRange, size_t cursor, size_t ubound )
	{
		/* Literal */
		if ( cursor > ubound )
			return Match.failure(inputRange);
		else if ( inputRange[cursor] == y )
			return Match.success(inputRange, cursor, cursor+1);
		else
			return Match.failure(inputRange);
	}

}

