/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
     Author: Mike Ulveling
    ===========================================================================*/
    
global virtual class FieldsetGridFactory {
    
    // !! note that each field actually uses 2 physical slots: 1 for the label, and 1 for the data:
    Integer globalFieldCounter = 0;
    // static cache for grid data, since getGridData() will be called a few times for each aspect:
    Map<Object, Grid> gridCache = new Map<Object, Grid>();
    // maintains intantiation order, which is crucial for preserving proper block segment allocations in the result from getGlobalFieldIndex():
    Grid[] gridInstances = new Grid[0];
    
    // !! this instance must be preserved in the ViewState, in order to maintain the proper block allocation segments across requests:
    global FieldsetGridFactory() {}
    
    global Grid defineGridInstance(Object gridIdent, GridBuilder builder) {
        System.assert(gridIdent != null, 'You must provide a non-null identifier to FieldsetGridFactory.defineGridInstance');
        Grid grid = gridCache.get(gridIdent);
        System.assert(grid == null, 'You cannot redefine grid instance \'' + gridIdent + '\'');
        
        grid = new Grid(this, gridIdent, builder);
        gridInstances.add(grid);
        gridCache.put(gridIdent, grid);
        
        return grid;
    }
    
    // note that a grid's destruction does NOT reclaim its segment allocation block -- this is crucial to preserving integrity of the global field
    // index:
    global void destroyGridInstance(Object gridIdent) {
        System.assert(gridIdent != null, 'You must provide a non-null identifier to FieldsetGridFactory.destroyGridInstance');
        Grid grid = gridCache.get(gridIdent);
        System.assert(grid != null, 'You have not defined grid instance \'' + gridIdent + '\'');
        
        gridCache.remove(gridIdent);
        for (Integer i=0; i < gridInstances.size(); i++) {
            if (gridInstances[i] === grid) {
                gridInstances.remove(i);
                break;
            }
        }
    }
    
    global Grid getGridInstance(Object gridIdent) {
        System.assert(gridIdent != null, 'You must provide a non-null identifier to FieldsetGridFactory.getGridInstance');
        Grid grid = gridCache.get(gridIdent);
        System.assert(grid != null, 'You have not defined grid instance \'' + gridIdent + '\'');
        return grid;
    }
    
    global GridField[] getGlobalFieldIndex() {
        GridField[] globalFieldIndex = new GridField[this.globalFieldCounter];
        // note that this segmentation allows for removed grid instances, and for instances added to the end:
        for (Grid g: gridInstances) {
            if (g == null) {
                
                // !! TODO: fill in "empty" fields for any holes we have left (i.e. from grid instances that were detroyed)
                
                continue;
            }
            
            GridField[] block = g.getGridFields();
            Integer i = g.globalFieldSegStart;
            for (GridField field: block)
                globalFieldIndex[i++] = field;
        }
        
        return globalFieldIndex;
    }
    
    global Map<Schema.sObjectType, Set<String>> getAllQueryFieldsByBindingType() {
        Map<Schema.sObjectType, Set<String>> all = new Map<Schema.sObjectType, Set<String>>();
        for (Grid g: gridInstances) {
            if (g == null)
                continue;
                
            for (GridField f: g.getGridData().indexedFields) {
                if (f.binding != null) {
                    Set<String> queryFields = all.get(f.binding.getSObjectType());
                    if (queryFields == null) {
                        all.put(f.binding.getSObjectType(), queryFields = new Set<String>());
                    }
                    queryFields.add(f.path.toLowerCase());
                }
            }
        }
        return all;
    }
    
    // necessary only because Visaulforce sucks and will call getters before your controller action method, thus sometimes filling cached vars with 
    // stale static/transient bindings:
    global void invalidateAllGridData() {
        for (Grid g: gridInstances) {
            if (g == null)
                continue;
        
            g.data = null;
        }
    }
    
    // !! these instances are preserved in the ViewState (this behavior is inherited from the parent factory), in order to maintain the proper block
    // allocation segments across requests:
    global class Grid {
        private FieldsetGridFactory factory;
        global Object ident {get; private set;}
        // note that 1 field slot equals 2 physical slots: 1 for the label, and 1 for the data
        global Integer globalFieldSegStart;
        global Integer globalFieldSlotsUsed = 0;
        
        global Integer absFieldIndexStart {get{ return globalFieldSegStart == null ? -1 : globalFieldSegStart * 2; }}
        global Integer absFieldIndexEnd {get{ return globalFieldSegStart == null ? -1 : (globalFieldSegStart + globalFieldSlotsUsed) * 2; }}
        
        global GridBuilder builder;
        
        // !! this is NOT preserved in the ViewState, to save space; it is the responsibility of FieldsetGridFactory.getGridInstance to recalc
        // gridData as necessary:
        transient GridData data;
        
        private Grid(FieldsetGridFactory factory, Object ident, GridBuilder builder) {
            this.factory = factory;
            this.ident = ident;
            this.builder = builder;
            this.globalFieldSegStart = factory.globalFieldCounter;
            recalcData(builder.toBlocks());
            this.globalFieldSlotsUsed = data.indexedFields.size();
            factory.globalFieldCounter += this.globalFieldSlotsUsed;
        }
        
        // !! it is the responsibility of FieldsetGridFactory.getGridInstance to call this method as necessary:
        private void recalcData(List<Column[]> gridBlocks) {
            this.data = new GridData();
            Integer physicalStartIndex = this.globalFieldSegStart * 2;
            for (Column[] block: gridBlocks) {
                physicalStartIndex = data.appendGridBlock(physicalStartIndex, block);
            }
        }
        
        global virtual Object getIdent() {
            return ident;
        }
        
        global GridData getGridData() {
            if (data == null)
                recalcData(builder.toBlocks());
            
            return data;
        }
        
        global String toJSON() {
            GridField[] tmp = getGridData().indexedFields;
            data.indexedFields = null;
            String j = JSON.serialize(data);
            data.indexedFields = tmp;
            return j;
        }
        
        global GridField[] getGridFields() {
            return getGridData().indexedFields;
        }
    }
    
    // !! these instances are NOT preserved in the ViewState, and are recalculated on-demand:
    global class GridData {
        public Object[] header;
        public List<Object[]> body = new List<Object[]>();
        public GridField[] indexedFields = new GridField[]{};
        public Integer numCols = 0;
        
        private GridData() {}
        
        // this is a no-op if the new # of cols is smaller than the existing #
        void resize(Integer newNumCols) {
            if (newNumCols < this.numCols)
                return;
            
            List<Object[]> newBody = new List<Object[]>();
            for (Object[] oldRow: body) {
                if (oldRow.size() == newNumCols * 2) {
                    newBody.add(oldRow);
                    continue;
                }
                
                Object[] newRow = new Object[0];
                newRow.addAll(oldRow);
                newRow.addAll(new Object[newNumCols * 2 - oldRow.size()]); // this will right-pad with null values as necessary
                newBody.add(newRow);
            }
            this.body = newBody;
            // note that data.header is really unused here:
            this.header = new Object[newNumCols * 2];
            this.numCols = newNumCols;
        }
        
        global Integer appendGridBlock(Integer cellIndex, Column[] cols) {
            // construct the header row for this block (simple "inline" labels):
            Object[] headerRow = new Object[]{};
            Boolean useHeaderRow = false;
            for (Column col: cols) {
                if (col.header != null) {
                    useHeaderRow = true;
                    // note that this doesn't inc the cellIndex:
                    headerRow.add(new Map<String, Object>{
                        'fieldSet' => col.firstFieldSet == null ? null : col.firstFieldSet.name,
                        'label' => col.header
                    });
                    // !! each column takes up 2 cells; 1 for label and 1 for data:
                    headerRow.add(null);
                } else {
                    // !! each column takes up 2 cells; 1 for label and 1 for data:
                    headerRow.add(null);
                    headerRow.add(null);
                }
            }
            if (useHeaderRow)
                this.body.add(headerRow);
            
            // calculate the max # of data rows across all columns in this block:
            Integer maxRows = 0;
            // the following 2 lists model the rows for each column:
            List<sObject[]> bindingsDeNormByCol = new List<sObject[]>(); // denormalized by each row
            List<FieldSetCollection.FieldSet[]> fieldSetsDeNormByCol = new List<FieldSetCollection.FieldSet[]>(); // denormalized by each row
            List<Integer[]> fieldBitsDeNormByCol = new List<Integer[]>();
            List<FieldSetCollection.Field[]> fieldsByCol = new List<FieldSetCollection.Field[]>();
            for (Column col: cols) {
                Integer colRows = 0;
                sObject[] colBindingsDeNorm = new sObject[]{};
                FieldSetCollection.FieldSet[] colFieldSetsDeNorm = new FieldSetCollection.FieldSet[]{};
                Integer[] colFieldBitsDeNorm = new Integer[]{};
                FieldSetCollection.Field[] colFields = new FieldSetCollection.Field[]{};
                Integer fsetIndex = 0;
                for (FieldSetCollection.FieldSet fset: col.fieldSets) {
                    sObject binding = col.bindings[fsetIndex];
                    Integer bits = col.propBits[fsetIndex];
                    for (FieldSetCollection.Field field: fset.fields) {
                        colBindingsDeNorm.add(binding);
                        colFieldSetsDeNorm.add(fset);
                        colFieldBitsDeNorm.add(bits);
                        colFields.add(field);
                    }
                    fsetIndex++;
                }
                bindingsDeNormByCol.add(colBindingsDeNorm);
                fieldSetsDeNormByCol.add(colFieldSetsDeNorm);
                fieldBitsDeNormByCol.add(colFieldBitsDeNorm);
                fieldsByCol.add(colFields);
                maxRows = Math.max(maxRows, colFields.size());
            }
            
            for (Integer rowIndex=0; rowIndex < maxRows; rowIndex++) {
                Object[] thisRow = new Object[]{};
                this.body.add(thisRow);
                Integer colIndex = 0;
                for (Column col: cols) {
                    sObject[] colBindingsDeNorm = bindingsDeNormByCol[colIndex];
                    FieldSetCollection.FieldSet[] colFieldSetsDeNorm = fieldSetsDeNormByCol[colIndex];
                    Integer[] colFieldBitsDeNorm = fieldBitsDeNormByCol[colIndex];
                    FieldSetCollection.Field[] colFields = fieldsByCol[colIndex];
                    
                    if (rowIndex < colFields.size()) {
                        sObject binding = colBindingsDeNorm[rowIndex];
                        FieldSetCollection.FieldSet fieldSet = colFieldSetsDeNorm[rowIndex];
                        Integer bits = colFieldBitsDeNorm[rowIndex];
                        FieldSetCollection.Field field = colFields[rowIndex];
                        this.indexedFields.add(new GridField(field, binding, bits));
                        thisRow.addAll(new Object[]{
                            new FieldCellLabel(cellIndex++, fieldSet, field),
                            new FieldCellData(cellIndex++, fieldSet, bits, field)
                        });
                    } else {
                        thisRow.addAll(new Object[]{null, null});
                    }
                    colIndex++;
                }
            }
            
            // adjust for a potentially disparate # of columns across prior blocks:
            this.resize(Math.max(this.numCols, cols.size()));
            return cellIndex;
        }
    }
    
    global class GridField {
        global FieldSetCollection.Field field {get; private set;}
        global String label {get{ return field.label; }}
        global Boolean useCustomLabel {get{ return field.useCustomLabel; }}
        global String labelName {get{ return field.labelName; }}
        global Boolean required {get{ return field.required; }}
        global String path {get{ return field.path; }}
        
        global sObject binding {get; private set;}
        global Integer propBits {get; private set;}
        global Boolean isIntake {get{
            return (propBits & INTAKE_BIT) > 0;
        }}
        
        GridField(FieldSetCollection.Field field, sObject binding, Integer propBits) {
            this.field = field;
            this.binding = binding;
            this.propBits = propBits;
        }
    }
    
    static final Integer INTAKE_BIT = 1;
    
    global class Column {
        global String header; // may be null
        global FieldSetCollection.FieldSet[] fieldSets = new FieldSetCollection.FieldSet[]{}; // may be empty, but not null 
        global sObject[] bindings = new sObject[]{}; // assert that this size equals the fieldSets size
        // a bitfield of flags; just the "intake" bit (lowest bit) for now:
        global Integer[] propBits = new Integer[]{}; // assert that this size equals the fieldSets size
        global FieldSetCollection.FieldSet firstFieldSet {get{ return fieldSets.size() == 0 ? null : fieldSets[0]; }}
        
        global Column(String header, FieldSetCollection.FieldSet fieldSet, sObject binding, Integer bits) {
            this.header = header;
            addFieldSet(fieldSet, binding, bits);
        }
        
        global Column(FieldSetCollection.FieldSet fieldSet, sObject binding, Integer bits) {
            this(null, fieldSet, binding, bits);
        }
        
        global Column(FieldSetCollection.FieldSet fieldSet, sObject binding) {
            this(null, fieldSet, binding, 0);
        }
        
        global void addFieldSet(FieldSetCollection.FieldSet fieldSet, sObject binding) {
            addFieldSet(fieldSet, binding, 0);
        }
        
        global void addFieldSet(FieldSetCollection.FieldSet fieldSet, sObject binding, Integer bits) {
            this.fieldSets.add(fieldSet);
            this.bindings.add(binding);
            this.propBits.add(bits);
        }
    }
    
    abstract class FieldCell {
        Integer index;
        String fieldSet;
        String path;
        String soapType;
        String displayType;
        String decClass;
        
        FieldCell(Integer index, FieldSetCollection.FieldSet fieldSet, FieldSetCollection.Field field) {
            this.fieldSet = fieldSet.name;
            this.index = index;
            this.path = field.path;
            this.soapType = field.soapType.name();
            this.displayType = field.displayType.name();
        }
    }
    
    class FieldCellLabel extends FieldCell {
        FieldCellLabel(Integer index, FieldSetCollection.FieldSet fieldSet, FieldSetCollection.Field field) {
            super(index, fieldSet, field);
            this.decClass = 'label';
        }
    }
    
    class FieldCellData extends FieldCell {
        FieldCellData(Integer index, FieldSetCollection.FieldSet fieldSet, Integer propBits, FieldSetCollection.Field field) {
            super(index, fieldSet, field);
            this.decClass = 'data ' + ((propBits & INTAKE_BIT) > 0 ? 'input' : 'output');
        }
    }
    
    global virtual class GridBuilder {
        global virtual List<Column[]> toBlocks() {
            System.assert(false, 'GridBuilder.toBlocks not implemented');
            return null;
        }
    }
    
    global class ColumnWiseBuilder extends GridBuilder {
        List<Column[]> blocks = new List<Column[]>();
        Column[] currBlock;
        sObject currBinding;
        Integer currPropBits = 0;
        
        Column currCol {get{
            if (currBlock.size() > 0)
                return currBlock[currBlock.size() - 1];
            else return null;
        }}
        
        global ColumnWiseBuilder() {
            this.blocks.add(this.currBlock = new Column[]{});
        }
        
        global ColumnWiseBuilder setBinding(sObject binding) {
            this.currBinding = binding;
            return this;
        }
        
        global ColumnWiseBuilder setIntake(Boolean isIntake) {
            this.currPropBits = isIntake == true ? currPropBits | INTAKE_BIT : currPropBits & ~INTAKE_BIT;
            return this;
        }
        
        global ColumnWiseBuilder col(String header, FieldSetCollection.FieldSet fieldSet) {
            Column col;
            this.currBlock.add(col = new Column(header, fieldSet, currBinding, currPropBits));
            return this;
        }
        
        global ColumnWiseBuilder addFieldSet(FieldSetCollection.FieldSet fieldSet) {
            Column currCol = currBlock[currBlock.size() - 1];
            currCol.addFieldSet(fieldSet, currBinding, currPropBits);
            return this;
        }
        
        global ColumnWiseBuilder nextBlock() {
            this.blocks.add(this.currBlock = new Column[]{});
            return this;
        }
        
        global override List<Column[]> toBlocks() {
            return blocks;
        }
    }
}