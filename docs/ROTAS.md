# Rotas da API

Gerado por `ContratoTest` a partir das classes `*Controller` (não editar à mão). 403 rotas, iguais às operações de `api/openapi.yaml`.
Documentação interactiva: `http://localhost:9080/openapi/ui` (servidor a correr).

## actividades

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/actividades/actividades` | ActividadesController · listar | `actividades.actividade.ler` |
| POST | `/v1/actividades/actividades` | ActividadesController · criar | `actividades.actividade.criar` |
| GET | `/v1/actividades/actividades/{id}` | ActividadesController · obter | `actividades.actividade.ler` |
| PATCH | `/v1/actividades/actividades/{id}` | ActividadesController · alterar | `actividades.actividade.alterar` |
| POST | `/v1/actividades/actividades/{id}/reactivar` | ActividadesController · reactivar | `actividades.actividade.terminar` |
| POST | `/v1/actividades/actividades/{id}/terminar` | ActividadesController · terminar | `actividades.actividade.terminar` |
| GET | `/v1/actividades/escalas` | EscalasController · listar | `actividades.escala.ler` |
| POST | `/v1/actividades/escalas` | EscalasController · criar | `actividades.escala.criar` |
| GET | `/v1/actividades/escalas-proximas` | RelatoriosActividadesController · escalasProximas | `actividades.escala.ler` |
| GET | `/v1/actividades/escalas/{id}` | EscalasController · obter | `actividades.escala.ler` |
| PATCH | `/v1/actividades/escalas/{id}` | EscalasController · alterar | `actividades.escala.alterar` |
| POST | `/v1/actividades/escalas/{id}/reactivar` | EscalasController · reactivar | `actividades.escala.terminar` |
| POST | `/v1/actividades/escalas/{id}/terminar` | EscalasController · terminar | `actividades.escala.terminar` |
| GET | `/v1/actividades/materiais` | MateriaisController · listar | `actividades.material.ler` |
| POST | `/v1/actividades/materiais` | MateriaisController · criar | `actividades.material.criar` |
| GET | `/v1/actividades/materiais/{id}` | MateriaisController · obter | `actividades.material.ler` |
| PATCH | `/v1/actividades/materiais/{id}` | MateriaisController · alterar | `actividades.material.alterar` |
| POST | `/v1/actividades/materiais/{id}/reactivar` | MateriaisController · reactivar | `actividades.material.terminar` |
| POST | `/v1/actividades/materiais/{id}/terminar` | MateriaisController · terminar | `actividades.material.terminar` |

## auth

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| POST | `/v1/auth/login` | AuthController · login | — |
| POST | `/v1/auth/recuperar` | AuthController · recuperar | — |
| POST | `/v1/auth/redefinir` | AuthController · redefinir | — |
| POST | `/v1/auth/renovar` | AuthController · renovar | — |
| POST | `/v1/auth/sair` | AuthController · sair | — |

## comunicacao

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/comunicacao/notificacoes` | NotificacoesController · listar | `comunicacao.notificacao.ler` |
| POST | `/v1/comunicacao/notificacoes` | NotificacoesController · criar | `comunicacao.notificacao.criar` |
| GET | `/v1/comunicacao/notificacoes-a-enviar` | RelatoriosComunicacaoController · notificacoesAEnviar | `comunicacao.notificacao.ler` |
| GET | `/v1/comunicacao/notificacoes/{id}` | NotificacoesController · obter | `comunicacao.notificacao.ler` |
| PATCH | `/v1/comunicacao/notificacoes/{id}` | NotificacoesController · alterar | `comunicacao.notificacao.alterar` |
| POST | `/v1/comunicacao/notificacoes/{id}/reactivar` | NotificacoesController · reactivar | `comunicacao.notificacao.terminar` |
| POST | `/v1/comunicacao/notificacoes/{id}/terminar` | NotificacoesController · terminar | `comunicacao.notificacao.terminar` |

## escola-sabatina

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/escola-sabatina/classes` | ClassesController · listar | `escola_sabatina.classe.ler` |
| POST | `/v1/escola-sabatina/classes` | ClassesController · criar | `escola_sabatina.classe.criar` |
| GET | `/v1/escola-sabatina/classes-trimestre` | ClassesTrimestreController · listar | `escola_sabatina.classe_trimestre.ler` |
| POST | `/v1/escola-sabatina/classes-trimestre` | ClassesTrimestreController · criar | `escola_sabatina.classe_trimestre.criar` |
| GET | `/v1/escola-sabatina/classes-trimestre/{id}` | ClassesTrimestreController · obter | `escola_sabatina.classe_trimestre.ler` |
| PATCH | `/v1/escola-sabatina/classes-trimestre/{id}` | ClassesTrimestreController · alterar | `escola_sabatina.classe_trimestre.alterar` |
| POST | `/v1/escola-sabatina/classes-trimestre/{id}/reactivar` | ClassesTrimestreController · reactivar | `escola_sabatina.classe_trimestre.terminar` |
| POST | `/v1/escola-sabatina/classes-trimestre/{id}/terminar` | ClassesTrimestreController · terminar | `escola_sabatina.classe_trimestre.terminar` |
| GET | `/v1/escola-sabatina/classes/{id}` | ClassesController · obter | `escola_sabatina.classe.ler` |
| PATCH | `/v1/escola-sabatina/classes/{id}` | ClassesController · alterar | `escola_sabatina.classe.alterar` |
| POST | `/v1/escola-sabatina/classes/{id}/reactivar` | ClassesController · reactivar | `escola_sabatina.classe.terminar` |
| POST | `/v1/escola-sabatina/classes/{id}/terminar` | ClassesController · terminar | `escola_sabatina.classe.terminar` |
| GET | `/v1/escola-sabatina/classificacao` | RelatoriosEscolaSabatinaController · classificacao | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/conferencia-ofertas` | RelatoriosEscolaSabatinaController · conferenciaOfertas | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/evolucao` | RelatoriosEscolaSabatinaController · evolucao | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/matriculas` | MatriculasController · listar | `escola_sabatina.matricula.ler` |
| POST | `/v1/escola-sabatina/matriculas` | MatriculasController · criar | `escola_sabatina.matricula.criar` |
| GET | `/v1/escola-sabatina/matriculas/{id}` | MatriculasController · obter | `escola_sabatina.matricula.ler` |
| PATCH | `/v1/escola-sabatina/matriculas/{id}` | MatriculasController · alterar | `escola_sabatina.matricula.alterar` |
| POST | `/v1/escola-sabatina/matriculas/{id}/reactivar` | MatriculasController · reactivar | `escola_sabatina.matricula.terminar` |
| POST | `/v1/escola-sabatina/matriculas/{id}/terminar` | MatriculasController · terminar | `escola_sabatina.matricula.terminar` |
| GET | `/v1/escola-sabatina/painel` | RelatoriosEscolaSabatinaController · painel | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/pesos-pontuacao` | PesosPontuacaoController · listar | — |
| POST | `/v1/escola-sabatina/pesos-pontuacao` | PesosPontuacaoController · criar | `escola_sabatina.pontuacao_config.criar` |
| GET | `/v1/escola-sabatina/pesos-pontuacao/{id}` | PesosPontuacaoController · obter | — |
| PATCH | `/v1/escola-sabatina/pesos-pontuacao/{id}` | PesosPontuacaoController · alterar | `escola_sabatina.pontuacao_config.alterar` |
| POST | `/v1/escola-sabatina/pesos-pontuacao/{id}/reactivar` | PesosPontuacaoController · reactivar | `escola_sabatina.pontuacao_config.terminar` |
| POST | `/v1/escola-sabatina/pesos-pontuacao/{id}/terminar` | PesosPontuacaoController · terminar | `escola_sabatina.pontuacao_config.terminar` |
| GET | `/v1/escola-sabatina/presencas` | PresencasController · listar | `escola_sabatina.presenca.ler` |
| POST | `/v1/escola-sabatina/presencas` | PresencasController · criar | `escola_sabatina.presenca.criar` |
| GET | `/v1/escola-sabatina/presencas/{id}` | PresencasController · obter | `escola_sabatina.presenca.ler` |
| PATCH | `/v1/escola-sabatina/presencas/{id}` | PresencasController · alterar | `escola_sabatina.presenca.alterar` |
| POST | `/v1/escola-sabatina/presencas/{id}/reactivar` | PresencasController · reactivar | `escola_sabatina.presenca.terminar` |
| POST | `/v1/escola-sabatina/presencas/{id}/terminar` | PresencasController · terminar | `escola_sabatina.presenca.terminar` |
| GET | `/v1/escola-sabatina/relatorio-associacao` | RelatoriosEscolaSabatinaController · relatorioAssociacao | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/relatorios-em-falta` | RelatoriosEscolaSabatinaController · relatoriosEmFalta | `escola_sabatina.relatorio_sabado.ler` |
| GET | `/v1/escola-sabatina/relatorios-sabado` | RelatoriosSabadoController · listar | `escola_sabatina.relatorio_sabado.ler` |
| POST | `/v1/escola-sabatina/relatorios-sabado` | RelatoriosSabadoController · criar | `escola_sabatina.relatorio_sabado.criar` |
| GET | `/v1/escola-sabatina/relatorios-sabado/{id}` | RelatoriosSabadoController · obter | `escola_sabatina.relatorio_sabado.ler` |
| PATCH | `/v1/escola-sabatina/relatorios-sabado/{id}` | RelatoriosSabadoController · alterar | `escola_sabatina.relatorio_sabado.alterar` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/fechar` | RelatoriosSabadoController · fechar | `escola_sabatina.relatorio_sabado.fechar` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/ofertas` | RelatoriosSabadoController · ofertas | `tesouraria.transacao.criar` |
| PUT | `/v1/escola-sabatina/relatorios-sabado/{id}/presencas` | RelatoriosSabadoController · presencas | `escola_sabatina.presenca.criar` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/reabrir` | RelatoriosSabadoController · reabrir | `escola_sabatina.relatorio_sabado.reabrir` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/reactivar` | RelatoriosSabadoController · reactivar | `escola_sabatina.relatorio_sabado.terminar` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/terminar` | RelatoriosSabadoController · terminar | `escola_sabatina.relatorio_sabado.terminar` |
| GET | `/v1/escola-sabatina/relatorios-sabado/{id}/visitantes` | RelatoriosSabadoController · visitantes | `escola_sabatina.visitante.ler` |
| POST | `/v1/escola-sabatina/relatorios-sabado/{id}/visitantes` | RelatoriosSabadoController · criarVisitante | `escola_sabatina.visitante.criar` |
| GET | `/v1/escola-sabatina/resumo-classes` | RelatoriosEscolaSabatinaController · resumoClasses | `escola_sabatina.classe_trimestre.ler` |
| GET | `/v1/escola-sabatina/sabados` | SabadosController · listar | — |
| POST | `/v1/escola-sabatina/sabados` | SabadosController · criar | `escola_sabatina.sabado.criar` |
| GET | `/v1/escola-sabatina/sabados/{id}` | SabadosController · obter | — |
| PATCH | `/v1/escola-sabatina/sabados/{id}` | SabadosController · alterar | `escola_sabatina.sabado.alterar` |
| POST | `/v1/escola-sabatina/sabados/{id}/reactivar` | SabadosController · reactivar | `escola_sabatina.sabado.terminar` |
| POST | `/v1/escola-sabatina/sabados/{id}/terminar` | SabadosController · terminar | `escola_sabatina.sabado.terminar` |
| GET | `/v1/escola-sabatina/trimestres` | TrimestresController · listar | — |
| POST | `/v1/escola-sabatina/trimestres` | TrimestresController · criar | `escola_sabatina.trimestre.criar` |
| GET | `/v1/escola-sabatina/trimestres/{id}` | TrimestresController · obter | — |
| PATCH | `/v1/escola-sabatina/trimestres/{id}` | TrimestresController · alterar | `escola_sabatina.trimestre.alterar` |
| POST | `/v1/escola-sabatina/trimestres/{id}/reactivar` | TrimestresController · reactivar | `escola_sabatina.trimestre.terminar` |
| POST | `/v1/escola-sabatina/trimestres/{id}/terminar` | TrimestresController · terminar | `escola_sabatina.trimestre.terminar` |
| GET | `/v1/escola-sabatina/visitantes` | VisitantesController · listar | `escola_sabatina.visitante.ler` |
| POST | `/v1/escola-sabatina/visitantes` | VisitantesController · criar | `escola_sabatina.visitante.criar` |
| GET | `/v1/escola-sabatina/visitantes-a-anonimizar` | RelatoriosEscolaSabatinaController · visitantesAAnonimizar | `escola_sabatina.visitante.ler` |
| GET | `/v1/escola-sabatina/visitantes/{id}` | VisitantesController · obter | `escola_sabatina.visitante.ler` |
| PATCH | `/v1/escola-sabatina/visitantes/{id}` | VisitantesController · alterar | `escola_sabatina.visitante.alterar` |
| POST | `/v1/escola-sabatina/visitantes/{id}/reactivar` | VisitantesController · reactivar | `escola_sabatina.visitante.terminar` |
| POST | `/v1/escola-sabatina/visitantes/{id}/terminar` | VisitantesController · terminar | `escola_sabatina.visitante.terminar` |

## eu

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/eu` | EuController · eu | — |

## nucleo

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/nucleo/auditoria` | AuditoriaController · listar | `nucleo.log_auditoria.ler` |
| GET | `/v1/nucleo/auditoria/{id}` | AuditoriaController · obter | `nucleo.log_auditoria.ler` |
| GET | `/v1/nucleo/perfis` | PerfisController · listar | — |
| POST | `/v1/nucleo/perfis` | PerfisController · criar | `nucleo.perfil.criar` |
| GET | `/v1/nucleo/perfis-permissoes` | PerfisPermissoesController · listar | — |
| POST | `/v1/nucleo/perfis-permissoes` | PerfisPermissoesController · criar | `nucleo.perfil_permissao.criar` |
| GET | `/v1/nucleo/perfis-permissoes/{id}` | PerfisPermissoesController · obter | — |
| PATCH | `/v1/nucleo/perfis-permissoes/{id}` | PerfisPermissoesController · alterar | `nucleo.perfil_permissao.alterar` |
| POST | `/v1/nucleo/perfis-permissoes/{id}/reactivar` | PerfisPermissoesController · reactivar | `nucleo.perfil_permissao.terminar` |
| POST | `/v1/nucleo/perfis-permissoes/{id}/terminar` | PerfisPermissoesController · terminar | `nucleo.perfil_permissao.terminar` |
| GET | `/v1/nucleo/perfis/{id}` | PerfisController · obter | — |
| PATCH | `/v1/nucleo/perfis/{id}` | PerfisController · alterar | `nucleo.perfil.alterar` |
| POST | `/v1/nucleo/perfis/{id}/reactivar` | PerfisController · reactivar | `nucleo.perfil.terminar` |
| POST | `/v1/nucleo/perfis/{id}/terminar` | PerfisController · terminar | `nucleo.perfil.terminar` |
| GET | `/v1/nucleo/permissoes` | PermissoesController · listar | — |
| POST | `/v1/nucleo/permissoes` | PermissoesController · criar | `nucleo.permissao.criar` |
| GET | `/v1/nucleo/permissoes/{id}` | PermissoesController · obter | — |
| PATCH | `/v1/nucleo/permissoes/{id}` | PermissoesController · alterar | `nucleo.permissao.alterar` |
| POST | `/v1/nucleo/permissoes/{id}/reactivar` | PermissoesController · reactivar | `nucleo.permissao.terminar` |
| POST | `/v1/nucleo/permissoes/{id}/terminar` | PermissoesController · terminar | `nucleo.permissao.terminar` |
| GET | `/v1/nucleo/usuarios` | UsuariosController · listar | `nucleo.usuario.ler` |
| POST | `/v1/nucleo/usuarios` | UsuariosController · criar | `nucleo.usuario.criar` |
| GET | `/v1/nucleo/usuarios-entidade` | UsuariosEntidadeController · listar | `nucleo.usuario_entidade.ler` |
| POST | `/v1/nucleo/usuarios-entidade` | UsuariosEntidadeController · criar | `nucleo.usuario_entidade.criar` |
| GET | `/v1/nucleo/usuarios-entidade/{id}` | UsuariosEntidadeController · obter | `nucleo.usuario_entidade.ler` |
| PATCH | `/v1/nucleo/usuarios-entidade/{id}` | UsuariosEntidadeController · alterar | `nucleo.usuario_entidade.alterar` |
| POST | `/v1/nucleo/usuarios-entidade/{id}/reactivar` | UsuariosEntidadeController · reactivar | `nucleo.usuario_entidade.terminar` |
| POST | `/v1/nucleo/usuarios-entidade/{id}/terminar` | UsuariosEntidadeController · terminar | `nucleo.usuario_entidade.terminar` |
| GET | `/v1/nucleo/usuarios-igreja` | UsuariosIgrejaController · listar | `nucleo.usuario_igreja.ler` |
| POST | `/v1/nucleo/usuarios-igreja` | UsuariosIgrejaController · criar | `nucleo.usuario_igreja.criar` |
| GET | `/v1/nucleo/usuarios-igreja/{id}` | UsuariosIgrejaController · obter | `nucleo.usuario_igreja.ler` |
| PATCH | `/v1/nucleo/usuarios-igreja/{id}` | UsuariosIgrejaController · alterar | `nucleo.usuario_igreja.alterar` |
| POST | `/v1/nucleo/usuarios-igreja/{id}/reactivar` | UsuariosIgrejaController · reactivar | `nucleo.usuario_igreja.terminar` |
| POST | `/v1/nucleo/usuarios-igreja/{id}/terminar` | UsuariosIgrejaController · terminar | `nucleo.usuario_igreja.terminar` |
| GET | `/v1/nucleo/usuarios/{id}` | UsuariosController · obter | `nucleo.usuario.ler` |
| PATCH | `/v1/nucleo/usuarios/{id}` | UsuariosController · alterar | `nucleo.usuario.alterar` |
| POST | `/v1/nucleo/usuarios/{id}/reactivar` | UsuariosController · reactivar | `nucleo.usuario.terminar` |
| POST | `/v1/nucleo/usuarios/{id}/terminar` | UsuariosController · terminar | `nucleo.usuario.terminar` |

## organizacao

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/organizacao/cargos` | CargosController · listar | — |
| POST | `/v1/organizacao/cargos` | CargosController · criar | `organizacao.cargo.criar` |
| GET | `/v1/organizacao/cargos/{id}` | CargosController · obter | — |
| PATCH | `/v1/organizacao/cargos/{id}` | CargosController · alterar | `organizacao.cargo.alterar` |
| POST | `/v1/organizacao/cargos/{id}/reactivar` | CargosController · reactivar | `organizacao.cargo.terminar` |
| POST | `/v1/organizacao/cargos/{id}/terminar` | CargosController · terminar | `organizacao.cargo.terminar` |
| GET | `/v1/organizacao/departamentos` | DepartamentosController · listar | — |
| POST | `/v1/organizacao/departamentos` | DepartamentosController · criar | `organizacao.departamento.criar` |
| GET | `/v1/organizacao/departamentos-igreja` | DepartamentosIgrejaController · listar | `organizacao.igreja_departamento.ler` |
| POST | `/v1/organizacao/departamentos-igreja` | DepartamentosIgrejaController · criar | `organizacao.igreja_departamento.criar` |
| GET | `/v1/organizacao/departamentos-igreja/{id}` | DepartamentosIgrejaController · obter | `organizacao.igreja_departamento.ler` |
| PATCH | `/v1/organizacao/departamentos-igreja/{id}` | DepartamentosIgrejaController · alterar | `organizacao.igreja_departamento.alterar` |
| POST | `/v1/organizacao/departamentos-igreja/{id}/reactivar` | DepartamentosIgrejaController · reactivar | `organizacao.igreja_departamento.terminar` |
| POST | `/v1/organizacao/departamentos-igreja/{id}/terminar` | DepartamentosIgrejaController · terminar | `organizacao.igreja_departamento.terminar` |
| GET | `/v1/organizacao/departamentos/{id}` | DepartamentosController · obter | — |
| PATCH | `/v1/organizacao/departamentos/{id}` | DepartamentosController · alterar | `organizacao.departamento.alterar` |
| POST | `/v1/organizacao/departamentos/{id}/reactivar` | DepartamentosController · reactivar | `organizacao.departamento.terminar` |
| POST | `/v1/organizacao/departamentos/{id}/terminar` | DepartamentosController · terminar | `organizacao.departamento.terminar` |
| GET | `/v1/organizacao/distritos` | DistritosController · listar | — |
| POST | `/v1/organizacao/distritos` | DistritosController · criar | `organizacao.distrito.criar` |
| GET | `/v1/organizacao/distritos/{id}` | DistritosController · obter | — |
| PATCH | `/v1/organizacao/distritos/{id}` | DistritosController · alterar | `organizacao.distrito.alterar` |
| POST | `/v1/organizacao/distritos/{id}/reactivar` | DistritosController · reactivar | `organizacao.distrito.terminar` |
| POST | `/v1/organizacao/distritos/{id}/terminar` | DistritosController · terminar | `organizacao.distrito.terminar` |
| GET | `/v1/organizacao/entidades` | EntidadesController · listar | — |
| POST | `/v1/organizacao/entidades` | EntidadesController · criar | `organizacao.entidade.criar` |
| GET | `/v1/organizacao/entidades/{id}` | EntidadesController · obter | — |
| PATCH | `/v1/organizacao/entidades/{id}` | EntidadesController · alterar | `organizacao.entidade.alterar` |
| POST | `/v1/organizacao/entidades/{id}/fundos-padrao` | EntidadesController · fundosPadrao | `tesouraria.fundo.criar` |
| POST | `/v1/organizacao/entidades/{id}/reactivar` | EntidadesController · reactivar | `organizacao.entidade.terminar` |
| POST | `/v1/organizacao/entidades/{id}/terminar` | EntidadesController · terminar | `organizacao.entidade.terminar` |
| GET | `/v1/organizacao/igrejas` | IgrejasController · listar | `organizacao.igreja.ler` |
| POST | `/v1/organizacao/igrejas` | IgrejasController · criar | `organizacao.igreja.criar` |
| GET | `/v1/organizacao/igrejas/{id}` | IgrejasController · obter | `organizacao.igreja.ler` |
| PATCH | `/v1/organizacao/igrejas/{id}` | IgrejasController · alterar | `organizacao.igreja.alterar` |
| POST | `/v1/organizacao/igrejas/{id}/reactivar` | IgrejasController · reactivar | `organizacao.igreja.terminar` |
| POST | `/v1/organizacao/igrejas/{id}/terminar` | IgrejasController · terminar | `organizacao.igreja.terminar` |

## pagamentos

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/pagamentos/bancarios` | BancariosController · listar | `pagamentos.pagamento_bancario.ler` |
| POST | `/v1/pagamentos/bancarios` | BancariosController · criar | `pagamentos.pagamento_bancario.criar` |
| GET | `/v1/pagamentos/bancarios/{id}` | BancariosController · obter | `pagamentos.pagamento_bancario.ler` |
| PATCH | `/v1/pagamentos/bancarios/{id}` | BancariosController · alterar | `pagamentos.pagamento_bancario.alterar` |
| POST | `/v1/pagamentos/bancarios/{id}/reactivar` | BancariosController · reactivar | `pagamentos.pagamento_bancario.terminar` |
| POST | `/v1/pagamentos/bancarios/{id}/terminar` | BancariosController · terminar | `pagamentos.pagamento_bancario.terminar` |
| GET | `/v1/pagamentos/mpesa` | MpesaController · listar | `pagamentos.pagamento_mpesa.ler` |
| POST | `/v1/pagamentos/mpesa` | MpesaController · criar | `pagamentos.pagamento_mpesa.criar` |
| GET | `/v1/pagamentos/mpesa-callbacks` | MpesaCallbacksController · listar | `pagamentos.mpesa_callback_log.ler` |
| POST | `/v1/pagamentos/mpesa-callbacks` | MpesaCallbacksController · criar | `pagamentos.mpesa_callback_log.criar` |
| GET | `/v1/pagamentos/mpesa-callbacks/{id}` | MpesaCallbacksController · obter | `pagamentos.mpesa_callback_log.ler` |
| PATCH | `/v1/pagamentos/mpesa-callbacks/{id}` | MpesaCallbacksController · alterar | `pagamentos.mpesa_callback_log.alterar` |
| POST | `/v1/pagamentos/mpesa-callbacks/{id}/reactivar` | MpesaCallbacksController · reactivar | `pagamentos.mpesa_callback_log.terminar` |
| POST | `/v1/pagamentos/mpesa-callbacks/{id}/terminar` | MpesaCallbacksController · terminar | `pagamentos.mpesa_callback_log.terminar` |
| GET | `/v1/pagamentos/mpesa-pendentes` | RelatoriosPagamentosController · mpesaPendentes | `pagamentos.pagamento_mpesa.ler` |
| POST | `/v1/pagamentos/mpesa/callback` | MpesaController · callback | `perfil INTEGRACAO` |
| GET | `/v1/pagamentos/mpesa/{id}` | MpesaController · obter | `pagamentos.pagamento_mpesa.ler` |
| PATCH | `/v1/pagamentos/mpesa/{id}` | MpesaController · alterar | `pagamentos.pagamento_mpesa.alterar` |
| POST | `/v1/pagamentos/mpesa/{id}/reactivar` | MpesaController · reactivar | `pagamentos.pagamento_mpesa.terminar` |
| POST | `/v1/pagamentos/mpesa/{id}/terminar` | MpesaController · terminar | `pagamentos.pagamento_mpesa.terminar` |

## secretaria

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/secretaria/baptismos` | BaptismosController · listar | `secretaria.baptismo.ler` |
| POST | `/v1/secretaria/baptismos` | BaptismosController · criar | `secretaria.baptismo.criar` |
| GET | `/v1/secretaria/baptismos/{id}` | BaptismosController · obter | `secretaria.baptismo.ler` |
| PATCH | `/v1/secretaria/baptismos/{id}` | BaptismosController · alterar | `secretaria.baptismo.alterar` |
| POST | `/v1/secretaria/baptismos/{id}/reactivar` | BaptismosController · reactivar | `secretaria.baptismo.terminar` |
| POST | `/v1/secretaria/baptismos/{id}/terminar` | BaptismosController · terminar | `secretaria.baptismo.terminar` |
| GET | `/v1/secretaria/cartas-pendentes` | RelatoriosSecretariaController · cartasPendentes | `secretaria.transferencia_membro.ler` |
| GET | `/v1/secretaria/censuras-activas` | RelatoriosSecretariaController · censurasActivas | `secretaria.disciplina.ler` |
| GET | `/v1/secretaria/consentimentos` | ConsentimentosController · listar | `secretaria.consentimento.ler` |
| POST | `/v1/secretaria/consentimentos` | ConsentimentosController · criar | `secretaria.consentimento.criar` |
| GET | `/v1/secretaria/consentimentos/{id}` | ConsentimentosController · obter | `secretaria.consentimento.ler` |
| PATCH | `/v1/secretaria/consentimentos/{id}` | ConsentimentosController · alterar | `secretaria.consentimento.alterar` |
| POST | `/v1/secretaria/consentimentos/{id}/reactivar` | ConsentimentosController · reactivar | `secretaria.consentimento.terminar` |
| POST | `/v1/secretaria/consentimentos/{id}/terminar` | ConsentimentosController · terminar | `secretaria.consentimento.terminar` |
| GET | `/v1/secretaria/contactos` | ContactosController · listar | `secretaria.contacto.ler` |
| POST | `/v1/secretaria/contactos` | ContactosController · criar | `secretaria.contacto.criar` |
| GET | `/v1/secretaria/contactos/{id}` | ContactosController · obter | `secretaria.contacto.ler` |
| PATCH | `/v1/secretaria/contactos/{id}` | ContactosController · alterar | `secretaria.contacto.alterar` |
| POST | `/v1/secretaria/contactos/{id}/reactivar` | ContactosController · reactivar | `secretaria.contacto.terminar` |
| POST | `/v1/secretaria/contactos/{id}/terminar` | ContactosController · terminar | `secretaria.contacto.terminar` |
| GET | `/v1/secretaria/disciplinas` | DisciplinasController · listar | `secretaria.disciplina.ler` |
| POST | `/v1/secretaria/disciplinas` | DisciplinasController · criar | `secretaria.disciplina.criar` |
| GET | `/v1/secretaria/disciplinas/{id}` | DisciplinasController · obter | `secretaria.disciplina.ler` |
| PATCH | `/v1/secretaria/disciplinas/{id}` | DisciplinasController · alterar | `secretaria.disciplina.alterar` |
| POST | `/v1/secretaria/disciplinas/{id}/reactivar` | DisciplinasController · reactivar | `secretaria.disciplina.terminar` |
| POST | `/v1/secretaria/disciplinas/{id}/terminar` | DisciplinasController · terminar | `secretaria.disciplina.terminar` |
| GET | `/v1/secretaria/familias` | FamiliasController · listar | `secretaria.familia.ler` |
| POST | `/v1/secretaria/familias` | FamiliasController · criar | `secretaria.familia.criar` |
| GET | `/v1/secretaria/familias-resumo` | RelatoriosSecretariaController · familiasResumo | `secretaria.familia.ler` |
| GET | `/v1/secretaria/familias/{id}` | FamiliasController · obter | `secretaria.familia.ler` |
| PATCH | `/v1/secretaria/familias/{id}` | FamiliasController · alterar | `secretaria.familia.alterar` |
| POST | `/v1/secretaria/familias/{id}/reactivar` | FamiliasController · reactivar | `secretaria.familia.terminar` |
| POST | `/v1/secretaria/familias/{id}/terminar` | FamiliasController · terminar | `secretaria.familia.terminar` |
| GET | `/v1/secretaria/mandatos-a-terminar` | RelatoriosSecretariaController · mandatosATerminar | `secretaria.oficial.ler` |
| GET | `/v1/secretaria/membros` | MembrosController · listar | `secretaria.membro.ler` |
| POST | `/v1/secretaria/membros` | MembrosController · criar | `secretaria.membro.criar` |
| GET | `/v1/secretaria/membros-basico` | RelatoriosSecretariaController · membrosBasico | `secretaria.membro.ler` |
| GET | `/v1/secretaria/membros/{id}` | MembrosController · obter | `secretaria.membro.ler` |
| PATCH | `/v1/secretaria/membros/{id}` | MembrosController · alterar | `secretaria.membro.alterar` |
| POST | `/v1/secretaria/membros/{id}/reactivar` | MembrosController · reactivar | `secretaria.membro.terminar` |
| POST | `/v1/secretaria/membros/{id}/terminar` | MembrosController · terminar | `secretaria.membro.terminar` |
| POST | `/v1/secretaria/membros/{id}/validar` | MembrosController · validar | `secretaria.membro.validar` |
| GET | `/v1/secretaria/menores-pendentes` | RelatoriosSecretariaController · menoresPendentes | `secretaria.membro.ler` |
| GET | `/v1/secretaria/movimentos-membro` | MovimentosMembroController · listar | `secretaria.movimento_membro.ler` |
| POST | `/v1/secretaria/movimentos-membro` | MovimentosMembroController · criar | `secretaria.movimento_membro.criar` |
| GET | `/v1/secretaria/movimentos-membro/{id}` | MovimentosMembroController · obter | `secretaria.movimento_membro.ler` |
| PATCH | `/v1/secretaria/movimentos-membro/{id}` | MovimentosMembroController · alterar | `secretaria.movimento_membro.alterar` |
| POST | `/v1/secretaria/movimentos-membro/{id}/reactivar` | MovimentosMembroController · reactivar | `secretaria.movimento_membro.terminar` |
| POST | `/v1/secretaria/movimentos-membro/{id}/terminar` | MovimentosMembroController · terminar | `secretaria.movimento_membro.terminar` |
| GET | `/v1/secretaria/oficiais` | OficiaisController · listar | `secretaria.oficial.ler` |
| POST | `/v1/secretaria/oficiais` | OficiaisController · criar | `secretaria.oficial.criar` |
| GET | `/v1/secretaria/oficiais/{id}` | OficiaisController · obter | `secretaria.oficial.ler` |
| PATCH | `/v1/secretaria/oficiais/{id}` | OficiaisController · alterar | `secretaria.oficial.alterar` |
| POST | `/v1/secretaria/oficiais/{id}/reactivar` | OficiaisController · reactivar | `secretaria.oficial.terminar` |
| POST | `/v1/secretaria/oficiais/{id}/terminar` | OficiaisController · terminar | `secretaria.oficial.terminar` |
| GET | `/v1/secretaria/relatorio-mensal` | RelatoriosSecretariaController · relatorioMensal | `secretaria.movimento_membro.ler` |
| GET | `/v1/secretaria/reunioes` | ReunioesController · listar | `secretaria.reuniao.ler` |
| POST | `/v1/secretaria/reunioes` | ReunioesController · criar | `secretaria.reuniao.criar` |
| GET | `/v1/secretaria/reunioes/{id}` | ReunioesController · obter | `secretaria.reuniao.ler` |
| PATCH | `/v1/secretaria/reunioes/{id}` | ReunioesController · alterar | `secretaria.reuniao.alterar` |
| POST | `/v1/secretaria/reunioes/{id}/reactivar` | ReunioesController · reactivar | `secretaria.reuniao.terminar` |
| POST | `/v1/secretaria/reunioes/{id}/terminar` | ReunioesController · terminar | `secretaria.reuniao.terminar` |
| GET | `/v1/secretaria/reunioes/{id}/votos` | ReunioesController · votos | `secretaria.voto.ler` |
| POST | `/v1/secretaria/reunioes/{id}/votos` | ReunioesController · criarVoto | `secretaria.voto.criar` |
| GET | `/v1/secretaria/transferencias` | TransferenciasController · listar | `secretaria.transferencia_membro.ler` |
| POST | `/v1/secretaria/transferencias` | TransferenciasController · criar | `secretaria.transferencia_membro.criar` |
| GET | `/v1/secretaria/transferencias/{id}` | TransferenciasController · obter | `secretaria.transferencia_membro.ler` |
| PATCH | `/v1/secretaria/transferencias/{id}` | TransferenciasController · alterar | `secretaria.transferencia_membro.alterar` |
| POST | `/v1/secretaria/transferencias/{id}/concluir` | TransferenciasController · concluir | `secretaria.transferencia_membro.aceitar` |
| POST | `/v1/secretaria/transferencias/{id}/emitir-carta` | TransferenciasController · emitirCarta | `secretaria.transferencia_membro.emitir_carta` |
| POST | `/v1/secretaria/transferencias/{id}/reactivar` | TransferenciasController · reactivar | `secretaria.transferencia_membro.terminar` |
| POST | `/v1/secretaria/transferencias/{id}/recusar` | TransferenciasController · recusar | `secretaria.transferencia_membro.alterar` |
| POST | `/v1/secretaria/transferencias/{id}/terminar` | TransferenciasController · terminar | `secretaria.transferencia_membro.terminar` |
| GET | `/v1/secretaria/votos` | VotosController · listar | `secretaria.voto.ler` |
| POST | `/v1/secretaria/votos` | VotosController · criar | `secretaria.voto.criar` |
| GET | `/v1/secretaria/votos/{id}` | VotosController · obter | `secretaria.voto.ler` |
| PATCH | `/v1/secretaria/votos/{id}` | VotosController · alterar | `secretaria.voto.alterar` |
| POST | `/v1/secretaria/votos/{id}/reactivar` | VotosController · reactivar | `secretaria.voto.terminar` |
| POST | `/v1/secretaria/votos/{id}/terminar` | VotosController · terminar | `secretaria.voto.terminar` |

## tesouraria

| Método | Caminho | Classe · método | Permissão |
| --- | --- | --- | --- |
| GET | `/v1/tesouraria/alvos` | AlvosController · listar | `tesouraria.alvo.ler` |
| POST | `/v1/tesouraria/alvos` | AlvosController · criar | `tesouraria.alvo.criar` |
| GET | `/v1/tesouraria/alvos/{id}` | AlvosController · obter | `tesouraria.alvo.ler` |
| PATCH | `/v1/tesouraria/alvos/{id}` | AlvosController · alterar | `tesouraria.alvo.alterar` |
| POST | `/v1/tesouraria/alvos/{id}/reactivar` | AlvosController · reactivar | `tesouraria.alvo.terminar` |
| POST | `/v1/tesouraria/alvos/{id}/terminar` | AlvosController · terminar | `tesouraria.alvo.terminar` |
| GET | `/v1/tesouraria/calendario-ofertas` | CalendarioOfertasController · listar | — |
| POST | `/v1/tesouraria/calendario-ofertas` | CalendarioOfertasController · criar | `tesouraria.calendario_oferta.criar` |
| GET | `/v1/tesouraria/calendario-ofertas/{id}` | CalendarioOfertasController · obter | — |
| PATCH | `/v1/tesouraria/calendario-ofertas/{id}` | CalendarioOfertasController · alterar | `tesouraria.calendario_oferta.alterar` |
| POST | `/v1/tesouraria/calendario-ofertas/{id}/reactivar` | CalendarioOfertasController · reactivar | `tesouraria.calendario_oferta.terminar` |
| POST | `/v1/tesouraria/calendario-ofertas/{id}/terminar` | CalendarioOfertasController · terminar | `tesouraria.calendario_oferta.terminar` |
| GET | `/v1/tesouraria/categorias` | CategoriasController · listar | — |
| POST | `/v1/tesouraria/categorias` | CategoriasController · criar | `tesouraria.categoria.criar` |
| GET | `/v1/tesouraria/categorias/{id}` | CategoriasController · obter | — |
| PATCH | `/v1/tesouraria/categorias/{id}` | CategoriasController · alterar | `tesouraria.categoria.alterar` |
| POST | `/v1/tesouraria/categorias/{id}/reactivar` | CategoriasController · reactivar | `tesouraria.categoria.terminar` |
| POST | `/v1/tesouraria/categorias/{id}/terminar` | CategoriasController · terminar | `tesouraria.categoria.terminar` |
| GET | `/v1/tesouraria/conferencia-contagens` | RelatoriosTesourariaController · conferenciaContagens | `tesouraria.contagem_numerario.ler` |
| GET | `/v1/tesouraria/contagens` | ContagensController · listar | `tesouraria.contagem_numerario.ler` |
| POST | `/v1/tesouraria/contagens` | ContagensController · criar | `tesouraria.contagem_numerario.criar` |
| GET | `/v1/tesouraria/contagens/{id}` | ContagensController · obter | `tesouraria.contagem_numerario.ler` |
| PATCH | `/v1/tesouraria/contagens/{id}` | ContagensController · alterar | `tesouraria.contagem_numerario.alterar` |
| POST | `/v1/tesouraria/contagens/{id}/reactivar` | ContagensController · reactivar | `tesouraria.contagem_numerario.terminar` |
| POST | `/v1/tesouraria/contagens/{id}/terminar` | ContagensController · terminar | `tesouraria.contagem_numerario.terminar` |
| GET | `/v1/tesouraria/contas` | ContasController · listar | `tesouraria.conta_financeira.ler` |
| POST | `/v1/tesouraria/contas` | ContasController · criar | `tesouraria.conta_financeira.criar` |
| GET | `/v1/tesouraria/contas/{id}` | ContasController · obter | `tesouraria.conta_financeira.ler` |
| PATCH | `/v1/tesouraria/contas/{id}` | ContasController · alterar | `tesouraria.conta_financeira.alterar` |
| POST | `/v1/tesouraria/contas/{id}/reactivar` | ContasController · reactivar | `tesouraria.conta_financeira.terminar` |
| POST | `/v1/tesouraria/contas/{id}/terminar` | ContasController · terminar | `tesouraria.conta_financeira.terminar` |
| GET | `/v1/tesouraria/contribuicoes` | RelatoriosTesourariaController · contribuicoes | `tesouraria.transacao.ler (ou o próprio membro)` |
| GET | `/v1/tesouraria/despesas` | DespesasController · listar | `tesouraria.despesa.ler` |
| POST | `/v1/tesouraria/despesas` | DespesasController · criar | `tesouraria.despesa.criar` |
| GET | `/v1/tesouraria/despesas-por-pagar` | RelatoriosTesourariaController · despesasPorPagar | `tesouraria.despesa.ler` |
| GET | `/v1/tesouraria/despesas/{id}` | DespesasController · obter | `tesouraria.despesa.ler` |
| PATCH | `/v1/tesouraria/despesas/{id}` | DespesasController · alterar | `tesouraria.despesa.alterar` |
| POST | `/v1/tesouraria/despesas/{id}/decidir` | DespesasController · decidir | `tesouraria.despesa.aprovar` |
| POST | `/v1/tesouraria/despesas/{id}/reactivar` | DespesasController · reactivar | `tesouraria.despesa.terminar` |
| POST | `/v1/tesouraria/despesas/{id}/terminar` | DespesasController · terminar | `tesouraria.despesa.terminar` |
| GET | `/v1/tesouraria/documentos` | DocumentosController · listar | `tesouraria.documento.ler` |
| POST | `/v1/tesouraria/documentos` | DocumentosController · criar | `tesouraria.documento.criar` |
| GET | `/v1/tesouraria/documentos/{id}` | DocumentosController · obter | `tesouraria.documento.ler` |
| PATCH | `/v1/tesouraria/documentos/{id}` | DocumentosController · alterar | `tesouraria.documento.alterar` |
| POST | `/v1/tesouraria/documentos/{id}/reactivar` | DocumentosController · reactivar | `tesouraria.documento.terminar` |
| POST | `/v1/tesouraria/documentos/{id}/terminar` | DocumentosController · terminar | `tesouraria.documento.terminar` |
| GET | `/v1/tesouraria/execucao-orcamento` | RelatoriosTesourariaController · execucaoOrcamento | `tesouraria.orcamento.ler` |
| GET | `/v1/tesouraria/extracto-anual` | RelatoriosTesourariaController · extractoAnual | `tesouraria.transacao.ler (ou o próprio membro)` |
| GET | `/v1/tesouraria/extractos` | ExtractosController · listar | `tesouraria.extrato_linha.ler` |
| POST | `/v1/tesouraria/extractos` | ExtractosController · criar | `tesouraria.extrato_linha.criar` |
| GET | `/v1/tesouraria/extractos-por-reconciliar` | RelatoriosTesourariaController · extractosPorReconciliar | `tesouraria.extrato_linha.ler` |
| POST | `/v1/tesouraria/extractos/importar` | ExtractosController · importar | `tesouraria.extrato_linha.criar` |
| GET | `/v1/tesouraria/extractos/{id}` | ExtractosController · obter | `tesouraria.extrato_linha.ler` |
| PATCH | `/v1/tesouraria/extractos/{id}` | ExtractosController · alterar | `tesouraria.extrato_linha.alterar` |
| POST | `/v1/tesouraria/extractos/{id}/reactivar` | ExtractosController · reactivar | `tesouraria.extrato_linha.terminar` |
| POST | `/v1/tesouraria/extractos/{id}/reconciliar` | ExtractosController · reconciliar | `tesouraria.extrato_linha.alterar` |
| POST | `/v1/tesouraria/extractos/{id}/terminar` | ExtractosController · terminar | `tesouraria.extrato_linha.terminar` |
| GET | `/v1/tesouraria/fechos` | FechosController · listar | `tesouraria.fecho_periodo.ler` |
| POST | `/v1/tesouraria/fechos` | FechosController · criar | `tesouraria.fecho_periodo.criar` |
| GET | `/v1/tesouraria/fechos/{id}` | FechosController · obter | `tesouraria.fecho_periodo.ler` |
| PATCH | `/v1/tesouraria/fechos/{id}` | FechosController · alterar | `tesouraria.fecho_periodo.alterar` |
| POST | `/v1/tesouraria/fechos/{id}/reabrir` | FechosController · reabrir | `tesouraria.fecho_periodo.terminar` |
| POST | `/v1/tesouraria/fechos/{id}/reactivar` | FechosController · reactivar | `tesouraria.fecho_periodo.terminar` |
| POST | `/v1/tesouraria/fechos/{id}/terminar` | FechosController · terminar | `tesouraria.fecho_periodo.terminar` |
| GET | `/v1/tesouraria/fundos` | FundosController · listar | `tesouraria.fundo.ler` |
| POST | `/v1/tesouraria/fundos` | FundosController · criar | `tesouraria.fundo.criar` |
| GET | `/v1/tesouraria/fundos/{id}` | FundosController · obter | `tesouraria.fundo.ler` |
| PATCH | `/v1/tesouraria/fundos/{id}` | FundosController · alterar | `tesouraria.fundo.alterar` |
| POST | `/v1/tesouraria/fundos/{id}/reactivar` | FundosController · reactivar | `tesouraria.fundo.terminar` |
| POST | `/v1/tesouraria/fundos/{id}/terminar` | FundosController · terminar | `tesouraria.fundo.terminar` |
| GET | `/v1/tesouraria/linhas-orcamento` | LinhasOrcamentoController · listar | `tesouraria.orcamento_linha.ler` |
| POST | `/v1/tesouraria/linhas-orcamento` | LinhasOrcamentoController · criar | `tesouraria.orcamento_linha.criar` |
| GET | `/v1/tesouraria/linhas-orcamento/{id}` | LinhasOrcamentoController · obter | `tesouraria.orcamento_linha.ler` |
| PATCH | `/v1/tesouraria/linhas-orcamento/{id}` | LinhasOrcamentoController · alterar | `tesouraria.orcamento_linha.alterar` |
| POST | `/v1/tesouraria/linhas-orcamento/{id}/reactivar` | LinhasOrcamentoController · reactivar | `tesouraria.orcamento_linha.terminar` |
| POST | `/v1/tesouraria/linhas-orcamento/{id}/terminar` | LinhasOrcamentoController · terminar | `tesouraria.orcamento_linha.terminar` |
| GET | `/v1/tesouraria/linhas-remessa` | LinhasRemessaController · listar | `tesouraria.remessa_linha.ler` |
| POST | `/v1/tesouraria/linhas-remessa` | LinhasRemessaController · criar | `tesouraria.remessa_linha.criar` |
| GET | `/v1/tesouraria/linhas-remessa/{id}` | LinhasRemessaController · obter | `tesouraria.remessa_linha.ler` |
| PATCH | `/v1/tesouraria/linhas-remessa/{id}` | LinhasRemessaController · alterar | `tesouraria.remessa_linha.alterar` |
| POST | `/v1/tesouraria/linhas-remessa/{id}/reactivar` | LinhasRemessaController · reactivar | `tesouraria.remessa_linha.terminar` |
| POST | `/v1/tesouraria/linhas-remessa/{id}/terminar` | LinhasRemessaController · terminar | `tesouraria.remessa_linha.terminar` |
| GET | `/v1/tesouraria/linhas-transacao` | LinhasTransacaoController · listar | `tesouraria.transacao_linha.ler` |
| POST | `/v1/tesouraria/linhas-transacao` | LinhasTransacaoController · criar | `tesouraria.transacao_linha.criar` |
| GET | `/v1/tesouraria/linhas-transacao/{id}` | LinhasTransacaoController · obter | `tesouraria.transacao_linha.ler` |
| PATCH | `/v1/tesouraria/linhas-transacao/{id}` | LinhasTransacaoController · alterar | `tesouraria.transacao_linha.alterar` |
| POST | `/v1/tesouraria/linhas-transacao/{id}/reactivar` | LinhasTransacaoController · reactivar | `tesouraria.transacao_linha.terminar` |
| POST | `/v1/tesouraria/linhas-transacao/{id}/terminar` | LinhasTransacaoController · terminar | `tesouraria.transacao_linha.terminar` |
| GET | `/v1/tesouraria/orcamentos` | OrcamentosController · listar | `tesouraria.orcamento.ler` |
| POST | `/v1/tesouraria/orcamentos` | OrcamentosController · criar | `tesouraria.orcamento.criar` |
| GET | `/v1/tesouraria/orcamentos/{id}` | OrcamentosController · obter | `tesouraria.orcamento.ler` |
| PATCH | `/v1/tesouraria/orcamentos/{id}` | OrcamentosController · alterar | `tesouraria.orcamento.alterar` |
| POST | `/v1/tesouraria/orcamentos/{id}/aprovar` | OrcamentosController · aprovar | `tesouraria.orcamento.aprovar` |
| POST | `/v1/tesouraria/orcamentos/{id}/reactivar` | OrcamentosController · reactivar | `tesouraria.orcamento.terminar` |
| POST | `/v1/tesouraria/orcamentos/{id}/terminar` | OrcamentosController · terminar | `tesouraria.orcamento.terminar` |
| GET | `/v1/tesouraria/progresso-alvos` | RelatoriosTesourariaController · progressoAlvos | `tesouraria.alvo.ler` |
| POST | `/v1/tesouraria/recalcular-saldos` | SaldosController · recalcular | `tesouraria.fecho_periodo.criar` |
| GET | `/v1/tesouraria/recibos` | RecibosController · listar | `tesouraria.recibo.ler` |
| POST | `/v1/tesouraria/recibos` | RecibosController · criar | `tesouraria.recibo.criar` |
| GET | `/v1/tesouraria/recibos/{id}` | RecibosController · obter | `tesouraria.recibo.ler` |
| PATCH | `/v1/tesouraria/recibos/{id}` | RecibosController · alterar | `tesouraria.recibo.alterar` |
| POST | `/v1/tesouraria/recibos/{id}/reactivar` | RecibosController · reactivar | `tesouraria.recibo.terminar` |
| POST | `/v1/tesouraria/recibos/{id}/terminar` | RecibosController · terminar | `tesouraria.recibo.terminar` |
| GET | `/v1/tesouraria/remessas` | RemessasController · listar | `tesouraria.remessa.ler` |
| POST | `/v1/tesouraria/remessas` | RemessasController · criar | `tesouraria.remessa.criar` |
| GET | `/v1/tesouraria/remessas-devidas` | RelatoriosTesourariaController · remessasDevidas | `tesouraria.saldo_diario_fundo.ler` |
| GET | `/v1/tesouraria/remessas/{id}` | RemessasController · obter | `tesouraria.remessa.ler` |
| PATCH | `/v1/tesouraria/remessas/{id}` | RemessasController · alterar | `tesouraria.remessa.alterar` |
| POST | `/v1/tesouraria/remessas/{id}/confirmar` | RemessasController · confirmar | `tesouraria.remessa.confirmar` |
| POST | `/v1/tesouraria/remessas/{id}/enviar` | RemessasController · enviar | `tesouraria.remessa.alterar` |
| POST | `/v1/tesouraria/remessas/{id}/reactivar` | RemessasController · reactivar | `tesouraria.remessa.terminar` |
| POST | `/v1/tesouraria/remessas/{id}/terminar` | RemessasController · terminar | `tesouraria.remessa.terminar` |
| GET | `/v1/tesouraria/saldos-contas` | RelatoriosTesourariaController · saldosContas | `tesouraria.conta_financeira.ler` |
| GET | `/v1/tesouraria/saldos-diarios-conta` | SaldosDiariosContaController · listar | `tesouraria.saldo_diario_conta.ler` |
| GET | `/v1/tesouraria/saldos-diarios-conta/{id}` | SaldosDiariosContaController · obter | `tesouraria.saldo_diario_conta.ler` |
| GET | `/v1/tesouraria/saldos-diarios-fundo` | SaldosDiariosFundoController · listar | `tesouraria.saldo_diario_fundo.ler` |
| GET | `/v1/tesouraria/saldos-diarios-fundo/{id}` | SaldosDiariosFundoController · obter | `tesouraria.saldo_diario_fundo.ler` |
| GET | `/v1/tesouraria/saldos-fundos` | RelatoriosTesourariaController · saldosFundos | `tesouraria.saldo_diario_fundo.ler` |
| GET | `/v1/tesouraria/transacoes` | TransacoesController · listar | `tesouraria.transacao.ler` |
| POST | `/v1/tesouraria/transacoes` | TransacoesController · criar | `tesouraria.transacao.criar` |
| GET | `/v1/tesouraria/transacoes/{id}` | TransacoesController · obter | `tesouraria.transacao.ler` |
| PATCH | `/v1/tesouraria/transacoes/{id}` | TransacoesController · alterar | `tesouraria.transacao.alterar` |
| POST | `/v1/tesouraria/transacoes/{id}/aprovar` | TransacoesController · aprovar | `tesouraria.transacao.aprovar` |
| POST | `/v1/tesouraria/transacoes/{id}/confirmar` | TransacoesController · confirmar | `tesouraria.transacao.alterar` |
| POST | `/v1/tesouraria/transacoes/{id}/estornar` | TransacoesController · estornar | `tesouraria.transacao.criar` |
| GET | `/v1/tesouraria/transacoes/{id}/linhas` | TransacoesController · linhas | `tesouraria.transacao_linha.ler` |
| POST | `/v1/tesouraria/transacoes/{id}/reactivar` | TransacoesController · reactivar | `tesouraria.transacao.terminar` |
| POST | `/v1/tesouraria/transacoes/{id}/recibo` | TransacoesController · recibo | `tesouraria.recibo.criar` |
| POST | `/v1/tesouraria/transacoes/{id}/terminar` | TransacoesController · terminar | `tesouraria.transacao.terminar` |

