#ifndef _SQUID_AGENT_H_
#define _SQUID_AGENT_H_

#include <Y2.h>
#include <scr/SCRAgent.h>

#include "squid_parser.h"

/**
 * This class provides SCR functionality.
 * Only this class creates YCP values (not SquidParser even SquidFile).
 */
class SquidAgent : public SCRAgent{
  private:
    SquidParser *_parser;

  public:
    SquidAgent() : _parser(NULL){}
    ~SquidAgent();

    /**
     * Provides SCR Read ().
     * Returns list where each item refers to one line in conf file. Each item
     * is list of parameters.
     * For example:
     *      conf file:
     *          acl QUERY urlpath_regex cgi-bin \?
     *          acl apache rep_header Server ^Apache
     *      SCR::Read:
     *          [ ["QUERY", "urlpath_regex", "cgi-bin", "\?" ],
     *            ["apache", "rep_header", "Server", "^Apache"]
     *          ]
     *
     * @param path Path that should be read.
     * @param arg Additional parameter.
     */
    YCPValue Read(const YCPPath &path, const YCPValue& arg = YCPNull(), const YCPValue& optarg = YCPNull() );

    /**
     * Provides SCR Write ().
     */
    YCPBoolean Write(const YCPPath &path, const YCPValue& value, const YCPValue& arg = YCPNull());

    /**
     * Provides SCR Dir().
     * If path is '.', than it returns list of available options (defined
     * in conf file).
     * If path is '.all_options' it returns list of all options found in
     * conf file (even not defined - commented...).
     * Otherwise returns empty list.
     */
    YCPList Dir(const YCPPath& path);

    /**
     * Used for mounting the agent.
     * .scr file should look like:
     *      .etc.squid
     *      `ag_squid(
     *          `SquidAgent("/path/to/conf/file")
     *      )
     */
    YCPValue otherCommand(const YCPTerm& term);
};

#endif
