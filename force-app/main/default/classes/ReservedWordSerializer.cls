/**
 * @Author : Kandisa Technologies
 * @description : This class is used to change the update ReservedWord with postfix og passed object
 * Usage: new ReservedWordSerializer(obj).getAsString();
 */
public class ReservedWordSerializer
{
    
    // true for pretty printing
    JsonGenerator g = Json.createGenerator(true);
    
    /**
     * @description Constuctor of class
     * @param obj
    */
    public ReservedWordSerializer(Object obj)
    {
        if (obj == null)
        {
            g.writeNull();
        }
        else if (obj instanceof Map<String,Object>)
        {
            traverseMap((Map<String,Object>)obj);
        }
        else if (obj instanceof List<Object>)
        {
            traverseList((List<Object>)obj);
        }
        else
        {
            g.writeObject(obj);
        }
    }

    /**
     * @description Method to return Object as a String
     * @return String
    */
    public String getAsString()
    {
        return g.getAsString();
    }
    
    void traverseMap(Map<String,Object> obj)
    {
        List<String> keys = new List<String>(obj.keySet());
        keys.sort();
        
        g.writeStartObject();
        for (String key : keys)
        {
            Object value = obj.get(key);
            g.writeFieldName(key + '_x'); // <------ reserved word safety here
            
            if (value == null)
            {
                g.writeNull();
            }
            else if (value instanceof Map<String,Object>)
            {
                traverseMap((Map<String,Object>)value);
            }
            else if (value instanceof List<Object>)
            {
                traverseList((List<Object>)value);
            }
            else
            {
                g.writeObject(value);
            }
        }
        g.writeEndObject();
    }
    
    void traverseList(List<Object> objs)
    {
        g.writeStartArray();
        for (Object obj : objs)
        {
            if (obj == null)
            {
                g.writeNull();
            }
            else if (obj instanceof Map<String,Object>)
            {
                traverseMap((Map<String,Object>)obj);
            }
            else if (obj instanceof List<Object>)
            {
                traverseList((List<Object>)obj);
            }
            else
            {
                g.writeObject(obj);
            }
        }
        g.writeEndArray();
    }


    /**
     * @description parameterized constructor
     * @param obj
     * @param suffixed
    */
    public ReservedWordSerializer(Object obj, String suffixed)
    {
        if (obj == null)
        {
            g.writeNull();
        }
        else if (obj instanceof Map<String,Object>)
        {
            traverseMap1((Map<String,Object>)obj, suffixed);
        }
        else if (obj instanceof List<Object>)
        {
            traverseList1((List<Object>)obj, suffixed);
        }
        else
        {
            g.writeObject(obj);
        }
    }
    

    void traverseMap1(Map<String,Object> obj, string suffixed)
    {
        List<String> keys = new List<String>(obj.keySet());
        keys.sort();
        
        g.writeStartObject();
        for (String key : keys)
        {
            Object value = obj.get(key);
            g.writeFieldName(key + '_'+suffixed); // <------ reserved word safety here
            
            if (value == null)
            {
                g.writeNull();
            }
            else if (value instanceof Map<String,Object>)
            {
                traverseMap1((Map<String,Object>)value, suffixed);
            }
            else if (value instanceof List<Object>)
            {
                traverseList1((List<Object>)value, suffixed);
            }
            else
            {
                g.writeObject(value);
            }
        }
        g.writeEndObject();
    }


     void traverseList1(List<Object> objs, String suffixed)
    {
        g.writeStartArray();
        for (Object obj : objs)
        {
            if (obj == null)
            {
                g.writeNull();
            }
            else if (obj instanceof Map<String,Object>)
            {
                traverseMap1((Map<String,Object>)obj,suffixed);
            }
            else if (obj instanceof List<Object>)
            {
                traverseList1((List<Object>)obj, suffixed);
            }
            else
            {
                g.writeObject(obj);
            }
        }
        g.writeEndArray();
    }
    
}