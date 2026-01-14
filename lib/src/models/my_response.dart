class MyResponse<T> {
  final int code; // 0 sukses, 1 gagal
  final String message;
  final T? data;

  MyResponse({required this.code, required this.message, this.data});
}
