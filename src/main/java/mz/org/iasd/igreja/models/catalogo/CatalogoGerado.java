package mz.org.iasd.igreja.models.catalogo;

import java.util.List;
import java.util.Map;

import mz.org.iasd.igreja.models.actividades.Actividade;
import mz.org.iasd.igreja.models.actividades.Escala;
import mz.org.iasd.igreja.models.actividades.EscalaDia;
import mz.org.iasd.igreja.models.actividades.EscalaPlano;
import mz.org.iasd.igreja.models.actividades.Material;
import mz.org.iasd.igreja.models.escolasabatina.Classe;
import mz.org.iasd.igreja.models.escolasabatina.ClasseTrimestre;
import mz.org.iasd.igreja.models.escolasabatina.Matricula;
import mz.org.iasd.igreja.models.escolasabatina.PontuacaoConfig;
import mz.org.iasd.igreja.models.escolasabatina.Presenca;
import mz.org.iasd.igreja.models.escolasabatina.RelatorioSabado;
import mz.org.iasd.igreja.models.escolasabatina.Sabado;
import mz.org.iasd.igreja.models.escolasabatina.Trimestre;
import mz.org.iasd.igreja.models.escolasabatina.Visitante;
import mz.org.iasd.igreja.models.nucleo.LogAuditoria;
import mz.org.iasd.igreja.models.nucleo.Notificacao;
import mz.org.iasd.igreja.models.nucleo.Perfil;
import mz.org.iasd.igreja.models.nucleo.PerfilPermissao;
import mz.org.iasd.igreja.models.nucleo.Permissao;
import mz.org.iasd.igreja.models.nucleo.Usuario;
import mz.org.iasd.igreja.models.nucleo.UsuarioEntidade;
import mz.org.iasd.igreja.models.nucleo.UsuarioIgreja;
import mz.org.iasd.igreja.models.organizacao.Cargo;
import mz.org.iasd.igreja.models.organizacao.Departamento;
import mz.org.iasd.igreja.models.organizacao.Distrito;
import mz.org.iasd.igreja.models.organizacao.Entidade;
import mz.org.iasd.igreja.models.organizacao.Igreja;
import mz.org.iasd.igreja.models.organizacao.IgrejaDepartamento;
import mz.org.iasd.igreja.models.secretaria.Baptismo;
import mz.org.iasd.igreja.models.secretaria.Consentimento;
import mz.org.iasd.igreja.models.secretaria.Contacto;
import mz.org.iasd.igreja.models.secretaria.Disciplina;
import mz.org.iasd.igreja.models.secretaria.Familia;
import mz.org.iasd.igreja.models.secretaria.Membro;
import mz.org.iasd.igreja.models.secretaria.MovimentoMembro;
import mz.org.iasd.igreja.models.secretaria.Oficial;
import mz.org.iasd.igreja.models.secretaria.Reuniao;
import mz.org.iasd.igreja.models.secretaria.TransferenciaMembro;
import mz.org.iasd.igreja.models.secretaria.Voto;
import mz.org.iasd.igreja.models.tesouraria.Alvo;
import mz.org.iasd.igreja.models.tesouraria.CalendarioOferta;
import mz.org.iasd.igreja.models.tesouraria.Categoria;
import mz.org.iasd.igreja.models.tesouraria.ContaFinanceira;
import mz.org.iasd.igreja.models.tesouraria.ContagemNumerario;
import mz.org.iasd.igreja.models.tesouraria.Despesa;
import mz.org.iasd.igreja.models.tesouraria.Documento;
import mz.org.iasd.igreja.models.tesouraria.ExtratoLinha;
import mz.org.iasd.igreja.models.tesouraria.FechoPeriodo;
import mz.org.iasd.igreja.models.tesouraria.Fundo;
import mz.org.iasd.igreja.models.tesouraria.MpesaCallbackLog;
import mz.org.iasd.igreja.models.tesouraria.Orcamento;
import mz.org.iasd.igreja.models.tesouraria.OrcamentoLinha;
import mz.org.iasd.igreja.models.tesouraria.PagamentoBancario;
import mz.org.iasd.igreja.models.tesouraria.PagamentoMpesa;
import mz.org.iasd.igreja.models.tesouraria.Recibo;
import mz.org.iasd.igreja.models.tesouraria.Remessa;
import mz.org.iasd.igreja.models.tesouraria.RemessaLinha;
import mz.org.iasd.igreja.models.tesouraria.SaldoDiarioConta;
import mz.org.iasd.igreja.models.tesouraria.SaldoDiarioFundo;
import mz.org.iasd.igreja.models.tesouraria.Transacao;
import mz.org.iasd.igreja.models.tesouraria.TransacaoLinha;
import mz.org.iasd.igreja.models.tipos.CanalNotificacao;
import mz.org.iasd.igreja.models.tipos.EsDivisao;
import mz.org.iasd.igreja.models.tipos.EstadoActividade;
import mz.org.iasd.igreja.models.tipos.EstadoCivil;
import mz.org.iasd.igreja.models.tipos.EstadoContagem;
import mz.org.iasd.igreja.models.tipos.EstadoDespesa;
import mz.org.iasd.igreja.models.tipos.EstadoEscala;
import mz.org.iasd.igreja.models.tipos.EstadoMembro;
import mz.org.iasd.igreja.models.tipos.EstadoNotificacao;
import mz.org.iasd.igreja.models.tipos.EstadoOrcamento;
import mz.org.iasd.igreja.models.tipos.EstadoRegisto;
import mz.org.iasd.igreja.models.tipos.EstadoRelatorio;
import mz.org.iasd.igreja.models.tipos.EstadoRemessa;
import mz.org.iasd.igreja.models.tipos.EstadoReuniao;
import mz.org.iasd.igreja.models.tipos.EstadoTransacao;
import mz.org.iasd.igreja.models.tipos.EstadoTransferencia;
import mz.org.iasd.igreja.models.tipos.EstadoValidacao;
import mz.org.iasd.igreja.models.tipos.FuncaoEscala;
import mz.org.iasd.igreja.models.tipos.MetodoPagamento;
import mz.org.iasd.igreja.models.tipos.ResultadoVoto;
import mz.org.iasd.igreja.models.tipos.Sexo;
import mz.org.iasd.igreja.models.tipos.TipoCategoria;
import mz.org.iasd.igreja.models.tipos.TipoConsentimento;
import mz.org.iasd.igreja.models.tipos.TipoConta;
import mz.org.iasd.igreja.models.tipos.TipoContacto;
import mz.org.iasd.igreja.models.tipos.TipoDocumento;
import mz.org.iasd.igreja.models.tipos.TipoEntidade;
import mz.org.iasd.igreja.models.tipos.TipoFundo;
import mz.org.iasd.igreja.models.tipos.TipoIgreja;
import mz.org.iasd.igreja.models.tipos.TipoMovimento;
import mz.org.iasd.igreja.models.tipos.TipoReuniao;
import mz.org.iasd.igreja.models.tipos.TipoTransacao;
import mz.org.iasd.igreja.models.tipos.TipoVoto;

/**
 * Lista dos models ({@code models/<modulo>/}) e dos tipos enumerados ({@code models/tipos/}).
 * O catálogo das operações-padrão é lido das anotações desses ficheiros ({@link LeitorModelos}).
 * <p>
 * GERADO por ferramentas/gen_catalogo.py a partir de database/gerador/defs.py. NÃO EDITAR À MÃO.
 */
public final class CatalogoGerado {

    private CatalogoGerado() {
    }

    public static final List<Class<? extends Enum<?>>> TIPOS = List.of(
            CanalNotificacao.class,
            EsDivisao.class,
            EstadoActividade.class,
            EstadoCivil.class,
            EstadoContagem.class,
            EstadoDespesa.class,
            EstadoEscala.class,
            EstadoMembro.class,
            EstadoNotificacao.class,
            EstadoOrcamento.class,
            EstadoRegisto.class,
            EstadoRelatorio.class,
            EstadoRemessa.class,
            EstadoReuniao.class,
            EstadoTransacao.class,
            EstadoTransferencia.class,
            EstadoValidacao.class,
            FuncaoEscala.class,
            MetodoPagamento.class,
            ResultadoVoto.class,
            Sexo.class,
            TipoCategoria.class,
            TipoConsentimento.class,
            TipoConta.class,
            TipoContacto.class,
            TipoDocumento.class,
            TipoEntidade.class,
            TipoFundo.class,
            TipoIgreja.class,
            TipoMovimento.class,
            TipoReuniao.class,
            TipoTransacao.class,
            TipoVoto.class);

    public static final List<Class<? extends Record>> MODELOS = List.of(
            Perfil.class,
            Permissao.class,
            PerfilPermissao.class,
            Usuario.class,
            UsuarioIgreja.class,
            UsuarioEntidade.class,
            LogAuditoria.class,
            Entidade.class,
            Distrito.class,
            Igreja.class,
            Departamento.class,
            IgrejaDepartamento.class,
            Cargo.class,
            Familia.class,
            Membro.class,
            Contacto.class,
            Consentimento.class,
            Reuniao.class,
            Voto.class,
            MovimentoMembro.class,
            TransferenciaMembro.class,
            Disciplina.class,
            Oficial.class,
            Baptismo.class,
            Actividade.class,
            Material.class,
            Escala.class,
            EscalaPlano.class,
            EscalaDia.class,
            Trimestre.class,
            Sabado.class,
            Classe.class,
            ClasseTrimestre.class,
            Matricula.class,
            RelatorioSabado.class,
            Presenca.class,
            Visitante.class,
            PontuacaoConfig.class,
            ContaFinanceira.class,
            Fundo.class,
            CalendarioOferta.class,
            Categoria.class,
            Alvo.class,
            Orcamento.class,
            OrcamentoLinha.class,
            Despesa.class,
            ContagemNumerario.class,
            Transacao.class,
            TransacaoLinha.class,
            SaldoDiarioConta.class,
            SaldoDiarioFundo.class,
            Recibo.class,
            Documento.class,
            Remessa.class,
            RemessaLinha.class,
            FechoPeriodo.class,
            ExtratoLinha.class,
            PagamentoMpesa.class,
            MpesaCallbackLog.class,
            PagamentoBancario.class,
            Notificacao.class);

    /** Valores de cada tipo enumerado do schema nucleo. */
    public static final Map<String, List<String>> ENUMS = LeitorModelos.enums(TIPOS);

    public static final List<Tabela> TABELAS = MODELOS.stream().map(LeitorModelos::tabela).toList();
}
