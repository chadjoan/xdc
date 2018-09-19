
struct Stash(T, initialLength : size_t)
{
	alias StashRef!(T,initialLength) StashRefT;
	private T[initialLength] initBuf = void;
	
	public StashRefT toRef() const
	{
		StashRefT result;
		result.initBuf = initBuf[0..$];
		result.theSlice = initBuf[0..0];
	}
}

struct StashRef(T)
{
	private T[] theSlice;
	private T[] initBuf;
	
	pure nothrow T[] opCast(T[])() const
	{
		return theSlice;
	}
	
	pure T opIndexopIndex(size_t i) const
	{
		return theSlice[i];
	}
	
	pure @property size_t length() const
	{
		return theSlice.length;
	}
	
	@property size_t length(size_t newLength)
{
		if ( newLength <= initBuf.length )
		{
			if ( theSlice.ptr is initBuf.ptr )
			{
				// When increasing allocation, be sure to initialize the
				//   new values.
				if ( theSlice.length < newLength )
					initBuf[theSlice.length .. newLength] = T.init;

				// Reallocate in-place.
				theSlice = initBuf[0..newLength];
			}
			else
			{
				// ptr != ptr: This means we want to move back to the
				//   originally allocated memory.  This could potentially allow
				//   the dynamically allocated memory to be free'd.
				// Since this is necessarily a shrinking operation, we don't
				//   have to worry about initializing any elements in initBuf.
				initBuf[0..newLength] = theSlice[0..newLength];
				theSlice = initBuf[0..newLength];
			}
		}
		else // Let the builtin handle the resize.
			theSlice.length = newLength;
		
		return theSlice.length;
	}
}

