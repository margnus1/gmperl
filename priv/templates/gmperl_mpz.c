#include "gmperl_nifs.h"
{% for f in mpz %}{% include "priv/templates/fun.c" %}{% endfor %}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_refeq)
{
    ERL_NIF_TERM ret;
    gmperl_privdata_t *priv = enif_priv_data(env);
    gmperl_mpz_t *val1, *val2;

    if (!enif_get_resource(env, argv[0], priv->gmperl_mpz_rt, (void**)&val1)) {
        goto badarg;
    }
    if (!enif_get_resource(env, argv[1], priv->gmperl_mpz_rt, (void**)&val2)) {
        goto badarg;
    }

    int val0 = val1->z == val2->z;
    ret = enif_get_boolean(env, val0);
    return ret;

 badarg:
    return enif_make_badarg(env);
}
