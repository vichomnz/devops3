import { useState } from "react";
import { CardComponent } from "./CardComponent";
import { Modal } from "./Modal";
import { FormVenta } from "./FormVenta";
import { TableCompras } from "./TableCompras";
import { TableDespachos } from "./TableDespachos";

export const PruebaCards = () => {
  const [tablaCompras, setTablaCompras] = useState(false);
  const [tablaOrdenes, setTablaOrdenes] = useState(false);
  const [openModalVenta, setOpenModalVenta] = useState(false);

  return (
    <section>
      <div className="flex justify-center">
        <CardComponent
          title="Consultar Ordenes de compra 💰"
          description="Revisa las últimas oc realizadas para generar su despacho"
          buttonText="Consultar"
          onClick={() => {
            setTablaCompras(true);
            setTablaOrdenes(false);
          }}
        />
        <CardComponent
          title="Revisar Ordenes de despacho 🚚"
          description="Consulta los despachos realizados, modifica los registros de intentos o cierra la orden"
          buttonText="Consultar"
          onClick={() => {
            setTablaCompras(false);
            setTablaOrdenes(true);
          }}
        />
      </div>

      <div className="flex justify-center mt-4">
        <button
          onClick={() => setOpenModalVenta(true)}
          className="bg-teal-600 hover:bg-teal-700 text-white font-bold py-3 px-8 rounded-xl shadow-md transition-all duration-300"
        >
          + Nueva Orden de Compra
        </button>
      </div>

      <section>
        {tablaCompras && <TableCompras />}
        {tablaOrdenes && <TableDespachos />}
      </section>

      <Modal open={openModalVenta} onClose={() => setOpenModalVenta(false)}>
        <FormVenta onClose={() => setOpenModalVenta(false)} />
      </Modal>
    </section>
  );
};
