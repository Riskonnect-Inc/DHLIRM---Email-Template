/*
=================================================================================================
|       AUTHOR      |       DATE        |                      DESCRIPTION                      |
=================================================================================================
|   Jason Bradley   |   May 1, 2018     | Added dynamic configuration + Migrate to Lightning    |
-------------------------------------------------------------------------------------------------
|                   |                   |                                                       |
*/

public class FishBoneController {
    // Controller private state
    @TestVisible
    private Id recordId {get; set;}

    @TestVisible
    private SObject record {get; set;}
    
    @TestVisible
    private FishboneConfig config {get; set;}

    // Controller public state
    public String fishboneData {get; set;}

    public FishBoneController() {
        Map<String, String> pageParams = normalizeParams(ApexPages.currentPage().getParameters());

        // Validate "id" URL param
        if (String.isBlank(pageParams.get('id'))) {
            throw new FishboneException(ERR_PARAM_NO_ID);
        }

        // Validate "config" URL param
        if (String.isBlank(pageParams.get('config'))) {
            throw new FishboneException(ERR_PARAM_NO_CONFIG);
        }

        // Read "id" URL param
        recordId = Id.valueOf(pageParams.get('id'));

        // Read "config" URL param
        String fishboneConfigRaw = pageParams.get('config');
        if (String.isBlank(fishboneConfigRaw)) {
            throw new FishboneException(ERR_PARAM_NO_CONFIG);
        }

        // Parse "config" URL param
        fishboneConfigRaw = EncodingUtil.urlDecode(fishboneConfigRaw, 'UTF-8');
        try {
            config = (FishboneConfig)JSON.deserialize(fishboneConfigRaw, FishboneConfig.class);
        } catch (JSONException e) {
            throw new FishboneException(ERR_PARAM_INVALID_CONFIG);
        }

        // Build query string for Fishbone's data
        String query = buildQueryFromConfig(this.config, recordId);

        // Retrieve the target record's data
        this.record = Database.query(query);

        // Create "root" node for Fishbone's data
        FishboneNode fishboneNode = new FishboneNode('');

        // For each root entry in the supplied config, add a new "rib" to the Fishbone
        for (String entryLabel : this.config.branchConfig.keySet()) {
            String fieldName = this.config.branchConfig.get(entryLabel);

            // Each "rib" consists of a root label, and a series of bones that branch
            // off of that (based on the entries in a multi-picklist field)
            fishboneNode.addChild(entryLabel)
                .addChildren(this.record.get(fieldName), ';');
        }

        // Serialize the final Fishbone data to JSON for the page
        this.fishboneData = fishboneNode.toJSON();
    }
           
    public FishBoneController(ApexPages.StandardController controller) {
        this();
    }

    // Error messages for any invalid operations
    @TestVisible
    private static final String ERR_PARAM_NO_ID = 'No record id supplied. Be sure to pass a record\'s Id via the "id" url parameter.';
    
    @TestVisible
    private static final String ERR_PARAM_NO_CONFIG = 'No fishbone configuration supplied. Be sure to pass the config via the "config" url parameter.';
    
    @TestVisible
    private static final String ERR_PARAM_INVALID_CONFIG = 'Invalid fishbone configuration supplied. Be sure to pass valid URL encoded JSON via the "config" url parameter.';

    // Exception wrapper for any configuration issues
    @TestVisible
    private class FishboneException extends Exception {}

    // Wrapper class for Fishbone JSON configuration
    public class FishboneConfig {
        public String sObjectName {get; set;}
        public Map<String, String> branchConfig {get; set;}
    }

    // Utility class to build out a query string from a FishboneConfig instance, and a record Id
    @TestVisible
    private static String buildQueryFromConfig(FishboneConfig config, Id recordId) {
        return 'SELECT ' + String.join(new List<String>(config.branchConfig.values()), ', ') + ' FROM ' + config.sObjectName + ' WHERE Id = \'' + recordId + '\'';
    }

    // Utility function to parse and remap URL parameters as their lowercase form. Helps with the id vs Id vs iD vs ID variants
    @TestVisible
    private static Map<String, String> normalizeParams(Map<String, String> params) {
        Map<String, String> response = new Map<String, String>();

        if (params != null) {
            for (String key : params.keySet()) {
                response.put(key.toLowerCase(), params.get(key));
            }
        }

        return response;
    }

    // Utility class to represent the JSON data sent to the client for the Fishbone visualization
    public class FishboneNode {
        public String name {get; set;}
        public FishboneNode[] children {get; set;}

        // No need to have this reference for the visualization, but it is useful for building out this structure
        // Marked as transient to keep it out of its serialized form
        transient FishboneNode parent {get; set;}

        public FishboneNode() {
            this('');
        }

        public FishboneNode(String name) {
            this.name = name;
            this.children = new FishboneNode[]{};
        }

        public FishboneNode(String name, FishboneNode parent) {
            this(name);
            this.parent = parent;
        }

        public FishboneNode addChild(String name) {
            FishboneNode child = new FishboneNode(name, this);
            this.children.add(child);
            return child;
        }

        public FishboneNode addChild(Object name) {
            return this.addChild(String.valueOf(name));
        }

        public FishboneNode addChildren(String[] names) {
            for (String name : names) {
                FishboneNode child = new FishboneNode(name, this);
                this.children.add(child);
            }
            return this;
        }

        public FishboneNode addChildren(String namesStr, String delimiter) {
            String[] names = new String[]{};
            if (String.isNotBlank(namesStr)) {
                names = namesStr.split(delimiter);
            }
            return this.addChildren(names);
        }

        public FishboneNode addChildren(Object namesStr, String delimiter) {
            return this.addChildren(String.valueOf(namesStr), delimiter);
        }

        public FishboneNode parent() {
            return this.parent;
        }

        public FishboneNode root() {
            if (this.parent != null) {
                return this.parent.root();
            } else {
                return this;
            }
        }

        public String toJSON() {
            return JSON.serialize(this.root());
        }
    }
}