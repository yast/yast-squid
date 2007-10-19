#ifndef _SQUID_PARSER_H_
#define _SQUID_PARSER_H_

#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <boost/regex.hpp>

#include "squid_file.h"
#include "debug.h"


class SquidParser{
  private:
    /**
     * Enumeration of states used by automat.
     */
    enum states_t {
        S_NOINFO,
        S_CONFIG,
        S_TAGGED_COMMENT,
        S_COMMENT,
        S_ERROR,
        S_END
    };

    /**
     * Identificators of regexps.
     */
    typedef enum regexps_t {
        R_COMMENT,
        R_TAGGED_COMMENT,
        R_CONFIG_OPTION,
        R_BLANK_LINE,
        R_NONE
    };

    /**
     * Input stream.
     */
    std::ifstream _in;

    /**
     * Current line read from _in.
     */
    std::string _current_line;

    /**
     * List of comment lines read from _in.
     */
    std::vector<std::string> _comments;

    /**
     * Tag of read comments.
     */
    std::string _comments_tag;

    /**
     * Matched strings from regexps.
     */
    boost::smatch _matched;

    /**
     * List of regexps (see regexps_t).
     */
    boost::regex _regexps[R_NONE + 1];

    /**
     * Current state of automat.
     */
    states_t _current_state;

    void _readNextLine();
    void _changeState(states_t);

    /**
     * Match current line against _regexps and return identifier defined
     * by regexps_t.
     */
    regexps_t _matchCurrentLine();

    void _addCurrentLineToComments();

    /**
     * Set tag to current read comments.
     */
    void _setCommentsAsTagged(boost::smatch matched_tag);
    void _setCommentsAsTaggedFromConfigOption(boost::smatch matched_tag);

    void _saveComments();
    void _saveConfigOption(boost::smatch matched_option);

    /**
     * Initialize regexps.
     */
    void _initRegexps()
    {
        _regexps[R_COMMENT] = "^#";
        _regexps[R_TAGGED_COMMENT] = "^#.*TAG:[ \\t]*([^ \\t\\n]+)";
        _regexps[R_CONFIG_OPTION] = "^[ \\t]*([^# \\t][^#]*[^# \\t])[ \\t]*(#.*){0,1}$";
        _regexps[R_BLANK_LINE] = "^[ \\t]*$";
    }


    void _noinfo();
    void _config();
    void _taggedComment();
    void _comment();
    void _error();
  public:
    SquidFile file;

    SquidParser(std::string filename);
    ~SquidParser(){}

    /**
     * Start parsing of _in.
     */
    void parse();
};
#endif
