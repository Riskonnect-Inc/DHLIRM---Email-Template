/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
  
global class StringBuilder {
    global String[] parts;
    global Integer top = -1;
    global Integer lmt = -1;
    global Integer expansionFactor = 2;
    
    global StringBuilder() {
        this(10);
    }
    
    global StringBuilder(Integer startSize) {
        parts = new String[Math.max(1, startSize)];
        lmt = startSize - 1;
    }
    
    // this method has an overhead of 1 statment when no lmt expansion is required, but in those cases
    // this push logic can be inlined into an existing expression for a net overhead of 0 statements. 
    // when lmt expansion is required, this method has an overhead of 2 statements, and an expansion 
    // will be necessary roughly LOG2(N) times. hence, with inlining, the net overhead of pushing N
    // elements would be O(LOG(N)) script statements.
    global StringBuilder push(String part) {
        if (top == lmt) {
            parts.addAll(new String[(this.lmt + 1) * (expansionFactor - 1)]);
            lmt = parts.size() - 1;
        }
        parts[++top] = part == null ? '' : part;
        return this;
    }

    // This "Log-Join" takes advantage of a savings in underlying memory allocations yielded by an
    // algorithm that's more clever than the usual straight-left-to-right string concatenation --
    // note that string concatenation is an associative operation.
    //
    // Intermediate buffer allocation efficiency here is N*LOG2(N) vs. N*N (apparently) for other 
    // Apex methods. Why? Because (assuming N elements of 1 char each):
    // 
    // Traditional left-to-right concatenation uses an average intermediate buffer size of N/2, and 
    // it creates a total of N-1 buffers, throwing away all but 1 of them (i.e. the final result)!
    // ((((((a + b) + c) + d) + e) + f) + g) + h
    //
    // Log-join iterates through LOG2(N) "levels" (rounds) from a depth of 1 to LOG2(N), where each 
    // level creates N/(2^depth) buffers of size 2^depth => 
    // LOG2(N) * N/(2^depth) * 2^depth => O(LOG2(N)*N)
    // (a + b) (c + d) (e + f) (g + h)
    // (ab + cd) (ef + gh)
    // abcd + efgh
    //
    // We still create the same number of memory buffers either way, but log-join keeps the average 
    // size of these buffers down at O(LOG2(N)) vs. O(N)!
    // 
    // Were Apex coded to leverage a Java StringBuffer/StringBuilder under-the-hood, then the
    // native methods would be O(N) efficiency and thus none of this madness would be necessary.
    //
    global String join(String sep) {
        if (top == 0)
            return parts[top];
        
        sep = sep == null ? '' : sep;
        // tracks the # of elements/intermediates relevant to the current "round":
        Integer upper = top + 1;
        // outer loop for approximately LOG (base 2) iterations:
        while (upper > 1) {
            // inner loop adjacently pairs up and concatenates the intermediate results:
            Integer i = 0; // write index
            Integer j = 0; // read index (1st element of current pair)
            // if we have a next pair of elements, then pair them up and advance to the next pair:
            while (j + 1 < upper) {
                parts[i++] = parts[j] + sep + parts[j + 1];
                j += 2;
            }
            // if we have a dangling element, then pass it into the next round:
            if (j < upper) {
                parts[i] = parts[j];
                // oops, we don't want our dangling element to get lopped off by the outer loop's
                // next integer-division by 2, so bump upper up to the next even number in preparation
                // for the next iteration -- think of the dangling element as a "remainder" from a 
                // modulus(upper, 2) operation:
                upper++;
            }
            // integer division; cut in half the # of elements we process in the next round:
            upper /= 2;
        }
        // hooray; our "simple" join procedure is done; the 1st element represents the final result. all other elements are garbage 
        // intermediates; contract the parts array so that we can continue with more parts and subsequent joins:
        top = 0;
        lmt = 9;
        String result = parts[0];
        parts = new String[10];
        parts[0] = result;
        return result;
    }
}