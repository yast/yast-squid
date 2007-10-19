#ifndef _SQUID_FILE_H_
#define _SQUID_FILE_H_

#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <iostream>

#include "debug.h"


/**
 * Class representing configuration file read by parser.
 */
class SquidFile{
  private:
    /**
     * Struct which defines block of conf file corresponding with one option.
     */
    struct option_block_t{
        std::string name; /*! name of the option */
        /*! list of comments. Each comment is list of lines from which
         *  the comment consists of. */
        std::vector<std::vector<std::string> > comments;
        /*! List of options. Each option is list of parameters. */
        std::vector<std::vector<std::string> > options;
    };

    /**
     * Return position of option with name option_name in vector
     * _options.
     * If option_name is not in vector return -1.
     */
    int _posInOptions(std::string &name) const;

    /**
     * Write given comments to fout.
     */
    void _writeComments(std::vector<std::vector<std::string> > &comments,
                        std::ofstream &fout) const;
    /**
     * Write given options to fout.
     */
    void _writeOptions(std::string &option_name,
                       std::vector<std::vector<std::string> > &options,
                       std::ofstream &fout) const;

    /**
     * Find proper place where to push comments or options with name
     * option_name. This method find the place according to contents
     * of variable _options_order.
     */
    std::vector<option_block_t *>::iterator
            _findProperPlace(std::string &option_name);


    /**
     * File where will be written settings.
     */
    std::string _filename;

    /**
     * List of read blocks of options.
     */
    std::vector<option_block_t *> _options;

    /**
     * Ordered list that defines in which order has to be options.
     * (Some options must be defined before others)
     * This list must be filled in constructor.
     */
    std::vector<std::string> _options_order;
  public:
    SquidFile(std::string filename);
    ~SquidFile();

    /**
     * Write settings.
     */
    bool write();

    /**
     * Add comments to the list.
     */
    void addComments(std::string option_name, std::vector<std::string> &comments);

    /**
     * Add configuration option to the list.
     */
    void addConfigOption(std::string option_name, std::vector<std::string> &options);


    /**
     * Returns list of all available options.
     * Memory pointed by returned pointer must be freed!
     */
    std::vector<std::string> *options();

    /**
     * Returns list of all options listed in conf file (even commented).
     * Memory pointed by returned pointer must be freed!
     */
    std::vector<std::string> *allOptions();

    /**
     * Returns list of parameters of option identified by option_name.
     * Memory pointed by returned pointer must be freed!
     */
    std::vector<std::vector<std::string> > *paramsOfOption(std::string option_name);


    /**
     * Assign to option with name option_name list of parameters params.
     */
    void changeOption(std::string option_name,
                      std::vector<std::vector<std::string> > &params);
};
#endif
