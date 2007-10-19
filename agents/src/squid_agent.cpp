#include "squid_agent.h"
using std::string;

SquidAgent::~SquidAgent()
{
    if (_parser != NULL)
        delete _parser;
}

YCPValue SquidAgent::Read(const YCPPath &path, const YCPValue& arg, const YCPValue& optarg)
{
    if (_parser == NULL){
        y2warning("Can't execute Dir before being mounted.");
        return YCPNull();
    }

    YCPList ret;
    vector<vector<string> > *params;
    int len, len2;
    string option_name;

    if (path->length() == 1){
        option_name = path->component_str(0);
        params = _parser->file.paramsOfOption(option_name);
        len = params->size();

        for (int i=0; i < len; i++){
            YCPList sublist;
            len2 = (*params)[i].size();

            for (int j=0; j < len2; j++){
                sublist.add(YCPString((*params)[i][j]));
            }
            ret.add(sublist);
        }

        delete params;
    }

    return ret;
}

/**
 * Helper function.
 */
static bool convertYCPListOfListOfStringToStd(const YCPList &value, vector<vector<string> > &std)
{
    int len = value->size();
    int len2;
    YCPValue val, val2;

    DBG("len: " << len);
    for (int i=0; i < len; i++){
        val = value->value(i);
        if (val->isList()){
            vector<string> vec;

            len2 = val->asList()->size();

            for (int j=0; j < len2; j++){
                val2 = val->asList()->value(j);
                if (val2->isString()){
                    vec.push_back(val2->asString()->value());
                }else{
                    return false;
                }
            }

            std.push_back(vec);
        }else{
            return false;
        }
    }

    return true;
}

YCPBoolean SquidAgent::Write(const YCPPath &path, const YCPValue& value, const YCPValue& arg)
{
    if (_parser == NULL){
        y2warning("Can't execute Dir before being mounted.");
        return YCPBoolean(false);
    }

    if (path->length() == 0){ // .
        DBG("`Write command called with path length 0.");
        return YCPBoolean(_parser->file.write());
    }else if (path->length() == 1 && value->isList()){ // .option
        vector<vector<string> > std_value;

        if (convertYCPListOfListOfStringToStd(value->asList(), std_value)){
            _parser->file.changeOption(path->component_str(0), std_value);
            return YCPBoolean(true);
        }

        return YCPBoolean(false);
    }else if (path->length() == 1 && value->isVoid()){
        vector<vector<string> > std_value;

        _parser->file.changeOption(path->component_str(0), std_value);
        return YCPBoolean(true);
    }

    return YCPBoolean(false);
}

YCPList SquidAgent::Dir(const YCPPath& path)
{
    if (_parser == NULL){
        y2warning("Can't execute Dir before being mounted.");
        return YCPNull();
    }

    YCPList ret;
    vector<string> *options;
    int len;

    if (path->isRoot() || path->toString() == ".all_options"){
        if (path->isRoot()){
            options = _parser->file.options();
        }else{ // path->toString() == ".all_options"
            options = _parser->file.allOptions();
        }

        len = options->size();
        for (int i=0; i < len; i++){
            ret.add(YCPString((*options)[i]));
        }

        delete options;
    }

    return ret;
}

YCPValue SquidAgent::otherCommand(const YCPTerm& term)
{
    string sym = term->name();

    if (sym == "SquidAgent"){
        if (term->size() == 1){
            if (!term->value(0)->isString()){
                return YCPError("Bad initialization of SquidFile(): agrument must be string.");
            }

            if (_parser != NULL)
                delete _parser;

            _parser = new SquidParser(term->value(0)->asString()->value());
            _parser->parse();

            return YCPVoid();
        }else{
            return YCPError("Bad initialization of SquidFile(): 1 argument expected.");
        }
    }

    return YCPNull();
}
