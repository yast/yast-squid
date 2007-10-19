#include "squid_parser.h"
#include <string>
#include <vector>
#include <boost/regex.hpp>

using std::string;
using std::istream;
using std::vector;

// private:
void SquidParser::_readNextLine()
{
    std::getline(_in, _current_line);
}

void SquidParser::_changeState(SquidParser::states_t new_state)
{
    _current_state = new_state;
}

SquidParser::regexps_t SquidParser::_matchCurrentLine()
{
    if (boost::regex_search(_current_line, _matched, _regexps[R_BLANK_LINE])){
        return R_BLANK_LINE;
    }else if (boost::regex_search(_current_line, _matched, _regexps[R_TAGGED_COMMENT])){
        return R_TAGGED_COMMENT;
    }else if (boost::regex_search(_current_line, _matched, _regexps[R_COMMENT])){
        return R_COMMENT;
    }else if (boost::regex_search(_current_line, _matched, _regexps[R_CONFIG_OPTION])){
        return R_CONFIG_OPTION;
    }

    return R_NONE;
}

void SquidParser::_addCurrentLineToComments()
{
    _comments.push_back(_current_line);
    _readNextLine();
}

void SquidParser::_setCommentsAsTagged(boost::smatch matched_tag)
{
    DBG("_setCommentsAsTagged() - matched_tag: " << matched_tag[1]);
    _comments_tag = matched_tag[1];
}

void SquidParser::_setCommentsAsTaggedFromConfigOption(boost::smatch matched_tag)
{
    DBG("_setCommentsAsTaggedFromConfigOption() - matched_tag: " << matched_tag[1]);

    string str = matched_tag[1];
    string::size_type lastPos = str.find_first_not_of(" \t", 0);
    string::size_type pos = str.find_first_of(" \t", lastPos);
    _comments_tag = str.substr(lastPos, pos - lastPos);
}


void SquidParser::_saveComments()
{
#ifndef NDEBUG
    DBG("");
    if (_comments_tag.size() > 0){
        DBG("===== DUMP TAGGED COMMENTS (tag: " << _comments_tag << ") =====");
    }else{
        DBG("===== DUMP COMMENTS =====");
    }
    int size = _comments.size();
    for (int i=0; i < size; i++){
        DBG(_comments[i]);
    }
    DBG("===== DUMP COMMENTS END =====");
    DBG("");
#endif

    file.addComments(_comments_tag, _comments);

    _comments.clear();
    _comments_tag.clear();
}


void SquidParser::_saveConfigOption(boost::smatch matched_option)
{
    DBG("_saveConfigOption: " << matched_option[1]);
    DBG("_saveConfigOption: matched_option.size(): " << matched_option.size());
    DBG("_saveConfigOption matched_option[2]: " << matched_option[2]);

    string str = matched_option[1];
    string option_name;
    vector<string> options;

    string::size_type lastPos = str.find_first_not_of(" \t", 0);
    string::size_type pos = str.find_first_of(" \t", lastPos);

    option_name = str.substr(lastPos, pos - lastPos);

    lastPos = str.find_first_not_of(" \t", pos);
    pos = str.find_first_of(" \t", lastPos);
    while (string::npos != pos || string::npos != lastPos)
    {
        options.push_back(str.substr(lastPos, pos - lastPos));

        lastPos = str.find_first_not_of(" \t", pos);
        pos = str.find_first_of(" \t", lastPos);
    }

    file.addConfigOption(option_name, options);

    if (matched_option.size() > 2 && ((string)matched_option[2]).size() > 0){
        vector<string> comments;
        comments.push_back(matched_option[2]);
        file.addComments(option_name, comments);
    }
}



void SquidParser::_noinfo()
{
    DBG("Entering _noinfo()");

    switch (_matchCurrentLine()){
        case R_COMMENT:
            _changeState(S_COMMENT);
            break;
        case R_TAGGED_COMMENT:
            _setCommentsAsTagged(_matched);
            _changeState(S_TAGGED_COMMENT);
            break;
        case R_CONFIG_OPTION:
            _changeState(S_CONFIG);
            break;
        case R_NONE:
            _changeState(S_ERROR);
            break;
        case R_BLANK_LINE:
            // skip blank lines
            DBG("skipping blank line");
            _readNextLine();
            break;
    }
}

void SquidParser::_config()
{
    DBG("Entering _config()");

    _saveConfigOption(_matched);
    _readNextLine();
    _changeState(S_NOINFO);
}

void SquidParser::_taggedComment()
{
    DBG("Entering _taggedComment()");

    _addCurrentLineToComments();

    switch (_matchCurrentLine()){
        case R_COMMENT:
        case R_TAGGED_COMMENT:
            break;
        default:
            _saveComments();
            _changeState(S_NOINFO);
            break;
    }
}

void SquidParser::_comment()
{
    DBG("Entering _comment()");

    _addCurrentLineToComments();

    switch (_matchCurrentLine()){
        case R_COMMENT:
            break;
        case R_TAGGED_COMMENT:
            _setCommentsAsTagged(_matched);
            _changeState(S_TAGGED_COMMENT);
            break;
        case R_CONFIG_OPTION:
            _setCommentsAsTaggedFromConfigOption(_matched);
            _saveComments();
            _changeState(S_CONFIG);
            break;
        default:
            _saveComments();
            _changeState(S_NOINFO);
            break;
    }
}

void SquidParser::_error()
{
    DBG("Entering _error()");
    DBG("Some error occured: skipping current line (" << _current_line << ")");
    _readNextLine(); // ignore this line
    _changeState(S_NOINFO);
}




// public:
SquidParser::SquidParser(std::string filename) :
            _current_state(S_NOINFO), file(filename)
{
    _initRegexps();
    _in.open(filename.c_str());
    if (!_in){
        DBG("Can't open file \"" << filename << "\"");
    }
}


void SquidParser::parse()
{
    DBG("start()");

    _readNextLine();

    while (_current_state != S_END && !_in.eof() && !_in.fail()){
        switch (_current_state){
            case S_NOINFO:
                _noinfo();
                break;
            case S_CONFIG:
                _config();
                break;
            case S_TAGGED_COMMENT:
                _taggedComment();
                break;
            case S_COMMENT:
                _comment();
                break;
            case S_ERROR:
                _error();
                break;
            case S_END:
                return;
        }
    }
}

