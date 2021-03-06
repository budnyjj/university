<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<h1>Архив заказов пользователя ${user.name}</h1>

<c:choose>
  <c:when test="${(orders.isEmpty())}">
    Вы еще не сделали ни одного заказа!
  </c:when>
  <c:otherwise>

    <table class="detail-parameters">
      <thead>
        <tr>
          <th class="flush-left">
            Название товара
          </th>
          <th class="flush-right">
            Цена
          </th>
          <th class="flush-right">
            Дата заказа
          </th>
        </tr>
      </thead>
      <tbody>
        <c:forEach var="order" items="${orders}" >
          <c:set var="bicycle" scope="session" value="${order.bicycle}"/>
          <tr>
            <td class="flush-left">
              <a class="brown-text" href="${pageContext.request.contextPath}/catalog/${bicycle.id}">
                ${bicycle.manufacturer} ${bicycle.productName}
              </a>
            </td>
            <td class="flush-right">${order.goodsCost}</td>
            <td class="flush-right">${order.orderDate}</td>
          </tr>
        </c:forEach>
      </tbody>
    </table>

  </c:otherwise>
</c:choose>

