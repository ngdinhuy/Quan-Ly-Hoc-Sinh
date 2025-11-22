# Add Meal Statistics Report

## Why
Admin cần theo dõi số lượng xuất ăn hàng ngày theo từng lớp để quản lý chi phí và lập kế hoạch bữa ăn. Hiện tại hệ thống đã có dữ liệu `danh_sach_ngay_cat_com` từ các yêu cầu về phép đã duyệt, nhưng chưa có màn hình thống kê tổng hợp.

## What Changes
- Thêm màn hình thống kê xuất ăn cho admin (web only)
- Hiển thị bảng thống kê theo từng lớp với các cột:
  - Tên lớp
  - Tổng số học sinh
  - Số học sinh cắt cơm (nghỉ ăn)
  - Số học sinh ăn cơm
- Cho phép chọn ngày để xem thống kê
- Cho phép chọn tháng/năm để xem tổng quan cả tháng
- Nút xuất Excel để download báo cáo
- Chỉ tính từ các yêu cầu về phép đã được duyệt (`daDuyet`)

## Impact
- Affected specs: None (new capability)
- Affected code:
  - New: `lib/screens/thong_ke_xuat_an_screen.dart` (admin screen)
  - New: `lib/services/thong_ke_xuat_an_service.dart` (statistics service)
  - Modified: `lib/services/xin_ve_phep_service.dart` (add query method)
  - Modified: Admin navigation (add menu item)
