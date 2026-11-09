import sys; import os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from defs import MODULES
RES = {  # nome do recurso na API (plural, com hífen)
 'perfil':'perfis','permissao':'permissoes','perfil_permissao':'perfis-permissoes','usuario':'usuarios',
 'usuario_igreja':'usuarios-igreja','usuario_entidade':'usuarios-entidade','log_auditoria':'auditoria',
 'entidade':'entidades','distrito':'distritos','igreja':'igrejas','departamento':'departamentos',
 'igreja_departamento':'departamentos-igreja','cargo':'cargos',
 'familia':'familias','membro':'membros','contacto':'contactos','consentimento':'consentimentos','reuniao':'reunioes',
 'voto':'votos','movimento_membro':'movimentos-membro','transferencia_membro':'transferencias','disciplina':'disciplinas',
 'oficial':'oficiais','baptismo':'baptismos',
 'actividade':'actividades','material':'materiais','escala':'escalas','escala_plano':'planos-escala','escala_dia':'dias-escala',
 'trimestre':'trimestres','sabado':'sabados','classe':'classes','classe_trimestre':'classes-trimestre','matricula':'matriculas',
 'relatorio_sabado':'relatorios-sabado','presenca':'presencas','visitante':'visitantes','pontuacao_config':'pesos-pontuacao',
 'conta_financeira':'contas','fundo':'fundos','calendario_oferta':'calendario-ofertas','categoria':'categorias','alvo':'alvos',
 'orcamento':'orcamentos','orcamento_linha':'linhas-orcamento','despesa':'despesas','contagem_numerario':'contagens',
 'transacao':'transacoes','transacao_linha':'linhas-transacao','saldo_diario_conta':'saldos-diarios-conta',
 'saldo_diario_fundo':'saldos-diarios-fundo','recibo':'recibos','documento':'documentos','remessa':'remessas',
 'remessa_linha':'linhas-remessa','fecho_periodo':'fechos','extrato_linha':'extractos',
 'pagamento_mpesa':'mpesa','mpesa_callback_log':'mpesa-callbacks','pagamento_bancario':'bancarios','notificacao':'notificacoes',
}
def modpath(schema): return schema.replace('_','-')
if __name__=='__main__':
    for f,s,t,d,ts in MODULES:
        print(s, ' '.join(RES[x.name] for x in ts))
    assert all(x.name in RES for m in MODULES for x in m[4])
