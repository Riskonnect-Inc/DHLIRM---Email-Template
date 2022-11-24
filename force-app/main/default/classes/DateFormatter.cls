/*===========================================================================
     Added to RK base RMIS product as  07/01/2013
    ===========================================================================*/
public with sharing class DateFormatter {
    public DateFormatter() {
        
    }

    public static Map<String, String> inferLocaleDateFormats() {
        // we choose a date that -- when formatted -- will not result in ambiguities between any 2 known locales:
        String x = Date.newInstance(2111, 3, 4).format();
        // a component is a string of 1 or more digits or 3 or more Unicode letters
        // !! note that we account for non-ASCII unicode letters and combining marks! see: http://www.regular-expressions.info/unicode.html
        String componentPatt = '([0-9]++|(?:\\p{L}\\p{M}*+){3,})';
        // this set of separator chars should cover the definition of separators listed in the following wikipedia article on locale date formats:
        // http://en.wikipedia.org/wiki/Date_format_by_country
        String sepPatt = '([/\\.\\-, ]*+)';
        Matcher m = Pattern.compile('(?i)^' + sepPatt + componentPatt + sepPatt + componentPatt + sepPatt + componentPatt + sepPatt + '$').matcher(x);
        System.assert(m.matches(), 'User locale has an unsupported/unrecognized date format [' + x + ']; wrong number of components');
        String[] comps = new String[]{ m.group(2), m.group(4), m.group(6) };
        String[] seps = new String[]{ m.group(1), m.group(3), m.group(5), m.group(7) };
        
        // Java uses SimpleDateFormat formatting; see: http://docs.oracle.com/javase/6/docs/api/java/text/SimpleDateFormat.html
        String[] javaFormat = new String[7];
        // jquery-ui's datepicker uses a different format from Java; see the $.datepicker.parseDate specifications at:
        // http://api.jqueryui.com/datepicker/
        String[] jquiFormat = new String[7];
        Integer i;
        String comp;
        
        // process the day component:
        for (i=0; i < comps.size(); i++) {
            comp = comps[i];
            Integer ival;
            try {
                ival = Integer.valueOf(comp);
            } catch (Exception ignore){} // ignore
            if (ival == 4) {
                javaFormat[2 * i + 1] = jquiFormat[2 * i + 1] = comp.length() == 1 ? 'd' : 'dd';
                break;
            }
        }
        System.assert(i < comps.size(), 'User locale has an unsupported/unrecognized date format [' + x + ']; could not find day component');
        
        // process the year component:
        for (i=0; i < comps.size(); i++) {
            comp = comps[i];
            Integer ival;
            try {
                ival = Integer.valueOf(comp);
            } catch (Exception ignore){} // ignore
            if (ival == 2111) {
                javaFormat[2 * i + 1] = 'yyyy';
                jquiFormat[2 * i + 1] = 'yy';
                break;
            } else if (ival == 11) {
                javaFormat[2 * i + 1] = 'yy';
                jquiFormat[2 * i + 1] = 'y';
                break;
            }
        }
        System.assert(i < comps.size(), 'User locale has an unsupported/unrecognized date format [' + x + ']; could not find year component');
        
        // process the month component:
        for (i=0; i < comps.size(); i++) {
            comp = comps[i];
            Integer ival;
            try {
                ival = Integer.valueOf(comp);
            } catch (Exception ignore){} // ignore
            if (ival == 3) {
                String formatPart = comp.length() == 1 ? 'M' : 'MM';
                javaFormat[2 * i + 1] = formatPart;
                jquiFormat[2 * i + 1] = formatPart.toLowerCase();
                break;
            }
        }
        // if we didn't match the month number, then there's a chance it's a wordy month (e.g. "Mar" or "March"):
        if (i == comps.size()) {
            // derive this locale's month names/abbreviations -- respecting the user's locale/language -- and try to re-parse by matching those:
            String name = Datetime.newInstance(2011, 3, 1).format('MMMMM');
            String shortName = Datetime.newInstance(2011, 3, 1).format('MMM');
            for (i=0; i < comps.size(); i++) {
                if (comps[i].equalsIgnoreCase(name)) {
                    javaFormat[2 * i + 1] = 'MMMMM';
                    jquiFormat[2 * i + 1] = 'MM';
                    break;
                } else if (comps[i].equalsIgnoreCase(shortName)) {
                    javaFormat[2 * i + 1] = 'MMM';
                    jquiFormat[2 * i + 1] = 'M';
                    break;
                }
            }
        }
        System.assert(i < comps.size(), 'User locale has an unsupported/unrecognized date format [' + x + ']; could not find month component');
        
        // transfer separator literals as-is:
        for (Integer j : new Integer[]{1, 3, 5, 7}) {
            javaFormat[j - 1] = jquiFormat[j - 1] = m.group(j) == null ? '' : m.group(j);
        }
        
        // we return a map so that we can expand the format types in the future as necessary:
        return new Map<String, String>{
            'java' => String.join(javaFormat, ''),
            'jquery-ui' => String.join(jquiFormat, '')
        };
    }

}