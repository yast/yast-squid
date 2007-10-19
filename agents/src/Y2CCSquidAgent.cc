#undef Y2LOG
#define Y2LOG "scr"
#include <scr/Y2AgentComponent.h>
#include <scr/Y2CCAgentComponent.h>
#undef Y2LOG
#define Y2LOG "agent-squid"

#include "squid_agent.h"


typedef Y2AgentComp <SquidAgent> Y2SquidAgentComp;

Y2CCAgentComp <Y2SquidAgentComp> g_y2ccag_squid ("ag_squid");

