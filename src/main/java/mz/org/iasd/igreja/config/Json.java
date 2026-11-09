package mz.org.iasd.igreja.config;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import jakarta.json.bind.JsonbConfig;
import jakarta.ws.rs.ext.ContextResolver;
import jakarta.ws.rs.ext.Provider;

/**
 * Configuração única do JSON: os campos a {@code null} são escritos (o contrato exige
 * {@code "proximo": null}, {@code "campo": null}, ...). Datas em ISO 8601 com fuso (padrão do JSON-B).
 */
@Provider
@ApplicationScoped
public class Json implements ContextResolver<Jsonb> {

    public static final Jsonb JSONB = JsonbBuilder.create(new JsonbConfig().withNullValues(true));

    @Override
    public Jsonb getContext(Class<?> tipo) {
        return JSONB;
    }
}
