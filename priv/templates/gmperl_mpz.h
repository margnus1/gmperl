#ifndef GMPERL_MPZ_H
#define GMPERL_MPZ_H

#include "gmperl_nifs.h"

{% for f in mpz %}{% include "priv/templates/fun.h" %}{% endfor %}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_refeq);
GMPERL_NIF_PROTOTYPE(gmperl_mpz_import);
GMPERL_NIF_PROTOTYPE(gmperl_mpz_export);
#endif // GMPERL_MPZ_H
