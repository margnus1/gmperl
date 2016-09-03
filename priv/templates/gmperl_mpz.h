#ifndef GMPERL_MPZ_H
#define GMPERL_MPZ_H

#include "gmperl_nifs.h"

{% for f in mpz %}{% include "priv/templates/fun.h" %}{% endfor %}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_refeq);
#endif // GMPERL_MPZ_H
