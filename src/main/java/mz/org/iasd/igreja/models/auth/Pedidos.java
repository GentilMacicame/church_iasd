package mz.org.iasd.igreja.models.auth;

import java.time.OffsetDateTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Corpos dos pedidos e respostas de /v1/auth (validação só de formato). */
public final class Pedidos {

    private Pedidos() {
    }

    public record Login(
            @NotBlank(message = "Indique o e-mail ou o telefone") @Size(max = 150) String login,
            @NotBlank(message = "Indique a senha") @Size(max = 200) String senha) {
    }

    public record Recuperar(
            @NotBlank(message = "Indique o e-mail ou o telefone") @Size(max = 150) String login) {
    }

    public record Redefinir(
            @NotBlank(message = "Indique o e-mail ou o telefone") @Size(max = 150) String login,
            @NotNull(message = "Indique o código recebido")
            @Pattern(regexp = "^\\d{6}$", message = "O código tem 6 dígitos") String codigo,
            @NotNull(message = "Indique a senha nova")
            @Size(min = 8, max = 200, message = "A senha tem de ter pelo menos 8 caracteres") String senha) {
    }

    public record Token(String tokenAcesso, OffsetDateTime expiraEm) {
    }
}
