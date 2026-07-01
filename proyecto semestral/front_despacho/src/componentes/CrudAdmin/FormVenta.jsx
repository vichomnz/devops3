import { useForm } from "react-hook-form";
import Swal from "sweetalert2";
import axios from "axios";
import { API_URL } from "../../api/config";

export const FormVenta = ({ onClose }) => {
  const { register, handleSubmit } = useForm();

  const onSubmit = async (data) => {
    const jsonData = {
      direccionCompra: data.direccionCompra,
      valorCompra: parseInt(data.valorCompra),
      fechaCompra: data.fechaCompra,
      despachoGenerado: false,
    };

    try {
      await axios.post(`${API_URL}/api/v1/ventas`, jsonData, {
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
      });
      Swal.fire({
        title: "Venta creada!",
        icon: "success",
        confirmButtonText: "Aceptar",
      });
    } catch (error) {
      console.error("Error:", error);
      Swal.fire({
        title: "Error",
        text: "No se pudo crear la venta",
        icon: "error",
        confirmButtonText: "Aceptar",
      });
    }
    onClose();
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col justify-center text-center px-24 text-xl">
      <div className="mx-auto text-3xl font-bold mb-10 text-teal-600">
        Nueva Orden de Compra
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Dirección</label>
        <input type="text" placeholder="Dirección de entrega" className="border border-gray-300 rounded-lg block w-full p-1" {...register("direccionCompra", { required: true })} />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Valor</label>
        <input type="number" placeholder="Valor de la compra" className="border border-gray-300 rounded-lg block w-full p-1" {...register("valorCompra", { required: true })} />
      </div>
      <div className="mb-5">
        <label className="block font-bold mb-2">Fecha de compra</label>
        <input type="date" className="border border-gray-300 rounded-lg block w-full p-1" {...register("fechaCompra", { required: true })} />
      </div>
      <button className="py-6 px-14 rounded-lg bg-teal-600 text-white font-bold mb-14" type="submit">
        Crear Venta
      </button>
    </form>
  );
};
