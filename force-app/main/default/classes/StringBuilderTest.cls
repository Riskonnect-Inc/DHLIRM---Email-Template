/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
      Author : Mike Ulveling
    ===========================================================================*/
@isTest
private class StringBuilderTest {

    @isTest
    static void testStringBuilder() {
        StringBuilder buf = new StringBuilder(10);
        buf.push('foo')
            .push('bar')
            .push('baz')
            .push('qux')
            .push('quux')
            .push('corge')
            .push('grault')
            .push('garply')
            .push('waldo')
            .push('fred')
            .push('plugh')
            .push('xyzzy')
            .push('thud');
        
        System.assertEquals('foo>bar>baz>qux>quux>corge>grault>garply>waldo>fred>plugh>xyzzy>thud', buf.join('>'));
    }
    
    static Object xxn = null;
    static final Integer NumOps = 150000;
    static final String element = 'a';
    static final String sep = ',';
    
    // typical timings [x150K, ',']: 900ms/1720ms -- significantly better than all other known methods
    // script statement overhead: between 0 (net) and N statements to add N parts, plus 0.2*N statements to join
    @isTest
    static void stringBuilderSpeedTest() {
        Datetime start = System.now();
        StringBuilder buf = new StringBuilder(10);
        Integer i = -1;
        while (++i < NumOps) { 
            if (buf.top == buf.lmt)
                buf.push(element);
            else
                buf.parts[++buf.top] = element;
        }
        Datetime joinStart = System.now();
        buf.join(sep);
        System.debug('StringBuilder [x' + NumOps + '; sep=\'' + sep 
                + '\'] join time: ' + (System.now().getTime() - joinStart.getTime()) 
                + '; total time: ' +  (System.now().getTime() - start.getTime()));
    }
    
    /* commented out because its takes so bloody long to run...
    // typical timings [x150K, ',']: more than 50 seconds -- yes, really. just awful :-o
    @isTest
    static void addOpSpeedTest() {
        Datetime start = System.now();
        Integer i=-1;
        String str = '';
        while (++i < NumOps) {
            if (sep == null) {
                str += element;
            } else {
                str += element + sep;
            }
        }
        System.debug('Native Add-Op [x' + NumOps + '; sep=\'' + sep + '\'] total time: ' + (System.now().getTime() - start.getTime()));
    }
    */
    
    // typical timings [x150K, ',']: 2800ms/5200ms
    // script statement overhead: N statements to add N parts; the join itself is essentially "free"
    // this is by far the most performant of the native methods for string concatenation, but it's still significantly slower then my StringBuffer:
    @isTest
    static void nativeJoinSpeedTest() {
        Datetime start = System.now();
        Integer i = 0;
        String[] parts = new String[]{};
        while (++i < NumOps) {
            parts.add(element);
        }
        Datetime joinStart = System.now();
        String.join(parts, sep == null ? '' : sep);
        System.debug((System.now().getTime() - start.getTime()));
        System.debug('Native String.join [x' + NumOps + '; sep=\'' + sep + '\'] join time: ' + (System.now().getTime() - joinStart.getTime()) + '; total time: ' +  (System.now().getTime() - start.getTime()));
    }
    
    /*
    // requires apex-lang installed as a managed package.
    // typical timings: hits script statement limit at ~100K+ elements; slower than all other methods before it hits the limit.
    // script statement overhead: 2*N statements for the combined add and join (the join is performed as each part is added) of N parts
    // al.StringUtils.join is a really, REALLY bad buffer/join implementation -- to do any worse, you'd have to make a concerted effort
    @isTest
    static void apexLangSpeedTest() {
        Datetime start = System.now();
        Integer i=-1;
        String[] parts = new String[]{};
        while (++i < NumOps) {
            parts.add(element);
        }
        Datetime joinStart = System.now();
        al.StringUtils.joinArray(parts, sep);
        System.debug('apex-lang [x' + NumOps + '; sep=\'' + sep + '\'] join time: ' + (System.now().getTime() - joinStart.getTime()) + '; total time: ' +  (System.now().getTime() - start.getTime()));
    }
    */
}