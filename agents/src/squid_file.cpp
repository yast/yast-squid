#include <algorithm>

#include "squid_file.h"
using std::string;
using std::vector;
using std::map;
using std::ofstream;
using std::endl;
using std::find;

// public:
SquidFile::SquidFile(std::string filename) : _filename(filename)
{
    _options_order.push_back("acl");

    _options_order.push_back("cache");
    _options_order.push_back("broken_vary_encoding");
    _options_order.push_back("access_log");
    _options_order.push_back("follow_x_forwarder_for");

    _options_order.push_back("http_access");
    _options_order.push_back("http_reply_access");
    _options_order.push_back("icp_access");
    _options_order.push_back("htcp_access");
    _options_order.push_back("htcp_clr_access");
    _options_order.push_back("miss_access");
    _options_order.push_back("cache_peer_access");
    _options_order.push_back("ident_lookup_access");
    _options_order.push_back("tcp_outgoing_tos");
    _options_order.push_back("tcp_outgoing_address");
    _options_order.push_back("reply_body_max_size");
    _options_order.push_back("log_access");
    _options_order.push_back("deny_info");
    _options_order.push_back("always_direct");
    _options_order.push_back("never_direct");
    _options_order.push_back("header_access");
    _options_order.push_back("snmp_access");
    _options_order.push_back("broken_posts");
}

SquidFile::~SquidFile()
{
    int len = _options.size();
    for (int i=0; i < len; i++){
        delete _options[i];
    }
}

bool SquidFile::write()
{
    DBG("Writing squid conf file.");
/*
#ifndef NDEBUG
    int len2 = _options.size();
    for (int i=0; i < len2; i++){
        DBG("");
        DBG("Option name: \"" << _options[i]->name << "\"");
        DBG("Comments:");
        for (unsigned int j=0; j < _options[i]->comments.size(); j++){
            for (unsigned int k=0; k < _options[i]->comments[j].size(); k++){
                DBG("    " << _options[i]->comments[j][k]);
            }
            DBG("");
        }

        DBG("Values:");
        for (unsigned int j=0; j < _options[i]->options.size(); j++){
            DBG2("    ");
            for (unsigned int k=0; k < _options[i]->options[j].size(); k++){
                DBG2(_options[i]->options[j][k] << " ");
            }
            DBG("");
        }
    }
#endif
*/

    int len;
    ofstream fout(_filename.c_str());
    if (!fout)
        return false;

    len = _options.size();
    for (int i=0; i < len; i++){
        _writeComments(_options[i]->comments, fout);
        _writeOptions(_options[i]->name, _options[i]->options, fout);
        fout << endl;
    }

    return true;
}

void SquidFile::addComments(string option_name, vector<string> &comments)
{
    if (option_name.size() == 0){
        option_block_t *new_block = new option_block_t;
        new_block->comments.push_back(comments);
        _options.push_back(new_block);

        return;
    }

    int pos = _posInOptions(option_name);
    if (pos == -1){
        option_block_t *new_block = new option_block_t;
        vector<option_block_t *>::iterator it = _findProperPlace(option_name);

        new_block->name = option_name;
        new_block->comments.push_back(comments);
        _options.insert(it, new_block);
        return;
    }

    _options[pos]->comments.push_back(comments);
}


void SquidFile::addConfigOption(string option_name, vector<string> &options)
{
    if (option_name.size() == 0){
        DBG("Can't add option value withou option_name.");
        return;
    }

    int pos = _posInOptions(option_name);
    if (pos == -1){
        option_block_t *new_block = new option_block_t;
        vector<option_block_t *>::iterator it = _findProperPlace(option_name);

        new_block->name = option_name;
        new_block->options.push_back(options);
        _options.insert(it, new_block);
        return;
    }

    _options[pos]->options.push_back(options);
}


vector<string> *SquidFile::options()
{
    vector<string> *ret = new vector<string>();
    int len = _options.size();

    for (int i=0; i < len; i++){
        if (_options[i]->name.size() > 0 && _options[i]->options.size() > 0)
            ret->push_back(_options[i]->name);
    }

    return ret;
}

vector<string> *SquidFile::allOptions()
{
    vector<string> *ret = new vector<string>();
    int len = _options.size();

    for (int i=0; i < len; i++){
        if (_options[i]->name.size() > 0)
            ret->push_back(_options[i]->name);
    }

    return ret;
}

vector<vector<string> > *SquidFile::paramsOfOption(std::string option_name)
{
    vector<vector<string> > *ret = new vector<vector<string> >();;
    int len;
    int pos = _posInOptions(option_name);

    if (pos != -1){
        len = _options[pos]->options.size();
        for (int i=0; i < len; i++){
            ret->push_back(_options[pos]->options[i]);
        }
    }

    return ret;
}


void SquidFile::changeOption(string option_name,
                             vector<vector<string> > &params)
{
    int pos = _posInOptions(option_name);
    if (pos == -1){
        int len = params.size();
        for (int i=0; i < len; i++){
            addConfigOption(option_name, params[i]);
        }
    }else{
        _options[pos]->options = params;
    }
}

// private:
int SquidFile::_posInOptions(std::string &name) const
{
    int len = _options.size();
    for (int i=0; i < len; i++){
        if (_options[i]->name == name)
            return i;
    }
    return -1;
}

void SquidFile::_writeComments(vector<vector<string> > &comments,
                               ofstream &fout) const
{
    int len, len2;
    len = comments.size();

    for (int i=0; i < len; i++){
        len2 = comments[i].size();
        for (int j=0; j < len2; j++){
            fout << comments[i][j] << endl;
        }
    }
}

void SquidFile::_writeOptions(string &option_name,
        vector<vector<string> > &options, ofstream &fout) const
{
    int len, len2;
    len = options.size();

    for (int i=0; i < len; i++){
        fout << option_name;

        len2 = options[i].size();
        for (int j=0; j < len2; j++){
            fout << " " << options[i][j];
        }

        fout << endl;
    }
}


vector<SquidFile::option_block_t *>::iterator SquidFile::_findProperPlace(string &option_name)
{
    vector<option_block_t *>::iterator it;
    vector<option_block_t *>::iterator it_end;
    vector<string>::iterator it_order =
        find(_options_order.begin(), _options_order.end(), option_name);

    if (it_order == _options_order.end() ||
        it_order+1 == _options_order.end())
        return _options.end();

    it_order++;
    it = _options.begin();
    it_end = _options.end();
    for (; it != it_end; it++){
        if (find(it_order, _options_order.end(), (*it)->name) != _options_order.end())
            break;
    }

    return it;
}
